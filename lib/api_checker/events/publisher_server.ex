defmodule ApiChecker.Events.PublisherServer do
  @moduledoc """
  GenServer wrapper around `ApiChecker.Events.Publisher` that publishes
  check result events to Kinesis asynchronously.

  `ApiChecker.TaskRunner` casts check results to this server instead of
  calling `ApiChecker.Events.Publisher.publish/2` directly, so that a
  slow (or failing) call to AWS Kinesis doesn't block other checks from
  running.
  """
  use GenServer
  alias ApiChecker.Events.Publisher

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @doc """
  Asynchronously publishes a check event for `check_name` with the
  given `success` boolean. Returns `:ok` immediately; the actual
  publish to Kinesis happens later, in the `#{inspect(__MODULE__)}`
  process.
  """
  @spec publish(String.t(), boolean, GenServer.server()) :: :ok
  def publish(check_name, success, server \\ __MODULE__)
      when is_binary(check_name) and is_boolean(success) do
    GenServer.cast(server, {:publish, check_name, success})
  end

  @impl true
  def init(_), do: {:ok, nil}

  @impl true
  def handle_cast({:publish, check_name, success}, state) do
    _ = Publisher.publish(check_name, success)
    {:noreply, state}
  end
end
