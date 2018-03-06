defmodule ApiChecker.Scheduler do
  @moduledoc """
  Responsible for making sure tasks run as scheduled.
  """

  use GenServer
  alias ApiChecker.TaskRunner

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :perform)
    {:ok, nil}
  end

  def handle_info(:perform, state) do
    tasks = ApiChecker.tasks_due!()
    previous_responses = ApiChecker.get_previous_responses()
    TaskRunner.perform(tasks, previous_responses)
    Process.send_after(self(), :perform, 10_000)
    {:noreply, state}
  end
end
