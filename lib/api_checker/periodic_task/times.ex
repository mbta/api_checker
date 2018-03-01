defmodule ApiChecker.PeriodicTask.Times do
  @doc """
  This is the timezone for MBTA is EST (Eastern Standard Time -0500).

  The "EST" in this function should probably be pulled from a config.
  """
  def service_timezone do
    # New York is the exact same thing as Boston. trololol.
    Timex.Timezone.get("America/New_York")
  end

  @doc """
  Converts any `DateTime` struct to a `DateTime` struct with 
  the service's timezone (EST in the case of MBTA).
  """
  def to_service_timezone(datetime) do
    Timex.Timezone.convert(datetime, service_timezone())
  end
end
