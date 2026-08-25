defmodule ApiChecker.Utilities do
  @moduledoc """
  General utility functions for ApiChecker.
  """

  # The API considers 3 AM to be the rollover from one service day to another
  @service_day_start_hour 3

  @doc """
  Given a `DateTime` in the service timezone, returns the service date and the GTFS
  time as total minutes since midnight of that service date.

  ## Examples

      iex> dt = %DateTime{year: 2024, month: 6, day: 15, hour: 10, minute: 30, second: 0,
      ...>   time_zone: "America/New_York", zone_abbr: "EDT", utc_offset: -18000, std_offset: 3600}
      iex> Utilities.service_date_and_gtfs_minutes(dt)
      {~D[2024-06-15], 630}

      iex> dt = %DateTime{year: 2024, month: 6, day: 15, hour: 1, minute: 0, second: 0,
      ...>   time_zone: "America/New_York", zone_abbr: "EDT", utc_offset: -18000, std_offset: 3600}
      iex> Utilities.service_date_and_gtfs_minutes(dt)
      {~D[2024-06-14], 1500}
  """
  def service_date_and_gtfs_minutes(%DateTime{} = dt) do
    if dt.hour < @service_day_start_hour do
      service_date = Date.add(DateTime.to_date(dt), -1)
      gtfs_minutes = (dt.hour + 24) * 60 + dt.minute
      {service_date, gtfs_minutes}
    else
      {DateTime.to_date(dt), dt.hour * 60 + dt.minute}
    end
  end

  @doc """
  Formats a GTFS minute count (which may exceed 24 * 60) as a "HH:MM" string.

  ## Examples

      iex> Utilities.format_gtfs_time(630)
      "10:30"

      iex> Utilities.format_gtfs_time(1500)
      "25:00"

      iex> Utilities.format_gtfs_time(245)
      "04:05"
  """
  def format_gtfs_time(minutes) when is_integer(minutes) and minutes >= 0 do
    h = div(minutes, 60)
    m = rem(minutes, 60)
    :io_lib.format("~2..0B:~2..0B", [h, m]) |> IO.iodata_to_binary()
  end
end
