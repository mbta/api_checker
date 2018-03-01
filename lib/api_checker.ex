defmodule ApiChecker do
  @moduledoc """
  Documentation for ApiChecker.
  """
  alias ApiChecker.{PeriodicTask, Schedule, PreviousResponse}

  def get_tasks() do
    Schedule.get_tasks()
  end

  def get_previous_responses() do
    PreviousResponse.get_all()
  end

  def tasks_due(tasks \\ get_tasks(), previous_responses \\ get_previous_responses(), datetime \\ DateTime.utc_now()) do
    Enum.filter(tasks, &task_due?(&1, previous_responses, datetime))
  end

  defp task_due?(task = %PeriodicTask{}, %DateTime{} = previous_datetime, %DateTime{} = datetime) do
    not PeriodicTask.too_soon_to_run?(task, previous_datetime, datetime)
    && PeriodicTask.intersects?(task, datetime)
  end
  defp task_due?(task, nil, datetime) do
    PeriodicTask.intersects?(task, datetime)
  end

  defp task_due?(task, previous_responses, datetime) when is_map(previous_responses) do
    previous_datetime =
      previous_responses
      |> Map.get(task.name, %{})
      |> Map.get(:updated_at)

    task_due?(task, previous_datetime, datetime)
  end

end
