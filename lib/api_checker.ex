defmodule ApiChecker do
  @moduledoc """
  Documentation for ApiChecker.
  """
  alias ApiChecker.{Schedule, PreviousResponse}

  def get_tasks() do
    Schedule.get_tasks()
  end

  def get_previous_responses() do
    PreviousResponse.get_all()
  end

  def tasks_due(tasks \\ get_tasks(), previous_response \\ get_previous_responses(), datetime \\ DateTime.utc_now()) do
  end
end
