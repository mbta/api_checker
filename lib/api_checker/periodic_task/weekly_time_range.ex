defmodule ApiChecker.PeriodicTask.WeeklyTimeRange do
  @moduledoc """
  Parses and validates time ranges for use in periodic tasks.

  A valid time range in string format is "HH:MM-HH:MM" where
  the time left of the dash is before the time on the right.
  """
  alias ApiChecker.PeriodicTask.{WeeklyTimeRange, Days}

  defstruct start: nil,
            stop: nil,
            day: nil

  @doc """
  Parses a valid time range string into a valid WeeklyTimeRange struct.

  iex> WeeklyTimeRange.from_json(%{"start" => "06:15", "stop" => "22:59", "day" => "WED"})
  {:ok, %WeeklyTimeRange{start: ~T[06:15:00], stop: ~T[22:59:00], day: "WED"}}

  iex> WeeklyTimeRange.from_json("22:59-06:15")
  {:error, :invalid_weekly_time_range_json}
  """
  def from_json(json) when is_map(json) do
    with {:ok, raw_start} <- Map.fetch(json, "start"),
         {:ok, raw_stop} <- Map.fetch(json, "stop"),
         {:ok, day} <- Map.fetch(json, "day"),
         {:ok, start} <- parse_time(raw_start),
         {:ok, stop} <- parse_time(raw_stop),
         time_range <- %WeeklyTimeRange{start: start, stop: stop, day: day},
         :ok <- validate(time_range) do
      {:ok, time_range}
    else
      {:error, _} = err ->
        err

      _ ->
        {:error, :invalid_weekly_time_range_json}
    end
  end

  def from_json(_) do
    {:error, :invalid_weekly_time_range_json}
  end

  @doc """
  Validates WeeklyTimeRange structs.

  iex> WeeklyTimeRange.validate(%WeeklyTimeRange{start: ~T[06:30:00], stop: ~T[06:50:00], day: "MON"})
  :ok

  iex> WeeklyTimeRange.validate(%WeeklyTimeRange{start: ~T[06:50:00], stop: ~T[06:30:00], day: "SUN"})
  {:error, :start_must_be_before_stop}

  iex> WeeklyTimeRange.validate(%WeeklyTimeRange{start: nil, stop: ~T[06:30:00], day: "FRI"})
  {:error, :invalid_weekly_time_range}
  """
  def validate(%WeeklyTimeRange{} = time_range) do
    with :ok <- validate_start_is_before_stop(time_range),
          :ok <- validate_day_of_week(time_range) do
      :ok
    else
      {:error, _} = err ->
        err
    end
  end

  def validate(_) do
    {:error, :invalid_time_range}
  end

  @doc """
  Turns valid time strings into {:ok %Time{}} or {:error, reason}

  iex> WeeklyTimeRange.parse_time("06:30")
  {:ok, ~T[06:30:00]}

  iex> WeeklyTimeRange.parse_time("06:30:30")
  {:ok, ~T[06:30:30]}

  iex> WeeklyTimeRange.parse_time("6:30")
  {:error, :invalid_time_format}
  """
  def parse_time(time) when is_binary(time) do
    with {:ok, formatted_time} <- ensure_time_has_seconds(time),
         {:ok, time_struct} <- Time.from_iso8601(formatted_time) do
      {:ok, time_struct}
    else
      _ ->
        # all errors become :invalid_time_format reasons
        {:error, :invalid_time_format}
    end
  end

  @doc """
  Ensures that a possible time string has seconds.

  Can handle the formats "H:MM:SS", "HH:MM:SS", "HH:MM" or "H:MM".

  In the case without the included seconds (without "SS"), the
  "SS" value is defaulted to "00" making the time precisely
  at the 0th second.

  Note: For this function we can largely ingore the format for hours
  and minutes under the assumption that the `Time.from_iso8601/1`
  function is used to convert possible time strings to Time structs.
  See the help for `parse_time/1` for valid time examples.

  iex> WeeklyTimeRange.ensure_time_has_seconds("12:13:14")
  {:ok, "12:13:14"}

  iex> WeeklyTimeRange.ensure_time_has_seconds("12:13")
  {:ok, "12:13:00"}

  iex> WeeklyTimeRange.ensure_time_has_seconds("2:13")
  {:ok, "2:13:00"}

  iex> WeeklyTimeRange.ensure_time_has_seconds("12")
  {:error, :invalid_time_format}
  """
  def ensure_time_has_seconds(time) when is_binary(time) do
    case String.split(time, ":") do
      [_, _] ->
        {:ok, time <> ":00"}

      [_, _, _] ->
        {:ok, time}

      _ ->
        {:error, :invalid_time_format}
    end
  end

  @doc """
  Ensures that a start time is before a stop time.

  iex> WeeklyTimeRange.validate_start_is_before_stop(%WeeklyTimeRange{start: ~T[06:30:00], stop: ~T[06:50:00]})
  :ok

  iex> WeeklyTimeRange.validate_start_is_before_stop(nil)
  {:error, :invalid_weekly_time_range}

  iex> WeeklyTimeRange.validate_start_is_before_stop(%WeeklyTimeRange{start: ~T[06:50:00], stop: ~T[06:30:00]})
  {:error, :start_must_be_before_stop}

  """
  def validate_start_is_before_stop(%WeeklyTimeRange{start: %Time{} = start, stop: %Time{} = stop}) do
    do_validate_start_is_before_stop(start, stop)
  end
  def validate_start_is_before_stop(_) do
    {:error, :invalid_weekly_time_range}
  end

  defp do_validate_start_is_before_stop(start, stop) do
    case Time.compare(start, stop) do
      :lt ->
        :ok

      _ ->
        {:error, :start_must_be_before_stop}
    end
  end

  def validate_day_of_week(%WeeklyTimeRange{day: day}) do
    if Days.is_day_of_week?(day) do
      :ok
    else
      {:error, :invalid_day_of_week}
    end
  end
end
