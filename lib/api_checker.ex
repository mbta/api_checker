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
end
