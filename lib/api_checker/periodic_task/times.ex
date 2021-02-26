defmodule ApiChecker.PeriodicTask.Times do
  @moduledoc """
  Functions for dealing with time/datetimes.
  """

  @doc """
  This is the timezone for MBTA: Eastern Standard Time
  """
  def service_timezone do
    # New York is the exact same thing as Boston. trololol.
    "America/New_York"
  end

  @doc """
  Converts any `DateTime` struct to a `DateTime` struct with
  the service's timezone.
  """
  def to_service_timezone(datetime) do
    DateTime.shift_zone!(datetime, service_timezone(), Tzdata.TimeZoneDatabase)
  end
end
