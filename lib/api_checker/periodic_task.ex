defmodule ApiChecker.PeriodicTask do
  @moduledoc """
  Provides context, parsing, validating for configuration of
  a PeriodicTask with the intention of configuring a worker process.
  """

  alias ApiChecker.PeriodicTask

  defstruct [
    frequency_in_seconds: nil,  # 120
    name: nil,                  # "mbta-bus-locations-weekdays" or "mbta-bus-locations-weekends"
    url:  nil,                  # "http://realtime.mbta.com/developer/api/v2/vehiclesbyroutes?api_key=9yaXQLoRF02t3UfWjxyiDQ&format=json&routes=1"
    days_to_call: [],           # three letter days of the week
    list_of_time_range: [],     # TimeRange ["05:59-23:59"]
    data_age_limit: nil,        # "DataAgeLimit": 300
    active: nil,                # "Active": true # boolean
  ]

  def from_json(_json) do
    %PeriodicTask{
      
    }
  end

  def validate(%PeriodicTask{} = task) do
    PeriodicTask.Validator.validate(task)
  end

end