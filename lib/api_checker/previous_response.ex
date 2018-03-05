defmodule ApiChecker.PreviousResponse do
  @moduledoc """
  Keeps track of previous responses.
  """

  use GenServer

  defstruct updated_at: nil,
            body: nil,
            status_code: nil

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_all() do
    GenServer.call(__MODULE__, :get_all)
  end

  def upsert(previous_responses) do
    GenServer.call(__MODULE__, {:upsert, previous_responses})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:upsert, latest_responses}, _from, previous_responses) do
    new_state = Map.merge(previous_responses, latest_responses)
    {:reply, new_state, new_state}
  end
end
