defmodule ApiChecker.PreviousResponse do
  @moduledoc """
  Keeps track of previous responses.
  """

  use GenServer
  alias ApiChecker.PeriodicTask

  defstruct updated_at: nil,
            body: nil,
            status_code: nil

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_all() do
    GenServer.call(__MODULE__, :get_all)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end
end
