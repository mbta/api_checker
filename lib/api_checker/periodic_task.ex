defmodule ApiChecker.PeriodicTask do
  @moduledoc """
  Provides context, parsing, validating for configuration of
  a PeriodicTask with the intention of configuring a worker process.
  """
  alias ApiChecker.PeriodicTask

  defstruct frequency_in_seconds: nil,

            # 120
            # "mbta-bus-locations-weekdays" or "mbta-bus-locations-weekends"
            name: nil,
            # "http://realtime.mbta.com/developer/api/v2/vehiclesbyroutes?api_key=9yaXQLoRF02t3UfWjxyiDQ&format=json&routes=1"
            url: nil,
            # three letter days of the week
            days_to_call: [],
            # TimeRange ["05:59-23:59"]
            list_of_time_range: [],
            # "DataAgeLimit": 300
            data_age_limit: nil,
            # "Active": true # boolean
            active: nil

  def from_json(_json) do
    %PeriodicTask{}
  end

  def validate(%PeriodicTask{} = task) do
    PeriodicTask.Validator.validate(task)
  end
end
