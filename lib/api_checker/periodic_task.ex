defmodule ApiChecker.PeriodicTask do
  @moduledoc """
  Provides context, parsing, validating for configuration of
  a PeriodicTask with the intention of configuring a worker process.
  """
  alias ApiChecker.PeriodicTask

  defstruct frequency_in_seconds: nil,
            name: nil,
            url: nil,
            time_ranges: [],
            data_age_limit: nil,
            active: nil

  def from_json(_json) do
    %PeriodicTask{}
  end

  def validate(%PeriodicTask{} = task) do
    PeriodicTask.Validator.validate(task)
  end
end
