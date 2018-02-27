defmodule ApiChecker.PeriodicTask.TimeRange do
  alias ApiChecker.PeriodicTask.TimeRange

  defstruct [
    start: nil,
    stop: nil,
  ]

  @doc """
  Parses a valid time range string into a valid TimeRange struct.

  iex> TimeRange.parse_string("06:15-22:59")
  {:ok, %TimeRange{start: ~T[06:15:00], stop: ~T[22:59:00]}}

  iex> TimeRange.parse_string("22:59-06:15")
  {:error, :start_must_be_before_stop}
  """
  def parse_string(item) when is_binary(item) do
    with \
      [raw_start, raw_stop] <- String.split(item, "-"),
      {:ok, start}  <- parse_time(raw_start),
      {:ok, stop}   <- parse_time(raw_stop),
      time_range    <- %TimeRange{start: start, stop: stop},
      :ok           <- validate(time_range)
    do
      {:ok, time_range}
    else
      {:error, _} = err ->
        err
      _ ->
        # did not split in the correct shape
        {:error, :invalid_time_range_string}
    end
  end

  @doc """
  Validates TimeRange structs.

  iex> TimeRange.validate(%TimeRange{start: ~T[06:30:00], stop: ~T[06:50:00]})
  :ok

  iex> TimeRange.validate(%TimeRange{start: ~T[06:50:00], stop: ~T[06:30:00]})
  {:error, :start_must_be_before_stop}

  iex> TimeRange.validate(%TimeRange{start: nil, stop: ~T[06:30:00]})
  {:error, :invalid_time_range}
  """
  def validate(%TimeRange{start: %Time{} = start, stop: %Time{} = stop}) do
    with \
      :ok  <- ensure_start_is_before_stop(start, stop)
    do
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

  iex> TimeRange.parse_time("06:30")
  {:ok, ~T[06:30:00]}

  iex> TimeRange.parse_time("06:30:30")
  {:ok, ~T[06:30:30]}

  iex> TimeRange.parse_time("6:30")
  {:error, :invalid_time_format}
  """
  def parse_time(time) when is_binary(time) do
    with \
      {:ok, formatted_time} <- ensure_time_has_seconds(time),
      {:ok, time_struct} <- Time.from_iso8601(formatted_time)
    do
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

  iex> TimeRange.ensure_time_has_seconds("12:13:14")
  {:ok, "12:13:14"}

  iex> TimeRange.ensure_time_has_seconds("12:13")
  {:ok, "12:13:00"}

  iex> TimeRange.ensure_time_has_seconds("2:13")
  {:ok, "2:13:00"}

  iex> TimeRange.ensure_time_has_seconds("12")
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

  iex> TimeRange.ensure_start_is_before_stop(~T[06:30:00], ~T[06:50:00])
  :ok

  iex> TimeRange.ensure_start_is_before_stop(~T[06:50:00], ~T[06:30:00])
  {:error, :start_must_be_before_stop}
  """
  def ensure_start_is_before_stop(start, stop) do
    case Time.compare(start, stop) do
      :lt ->
        :ok
      _ ->
        {:error, :start_must_be_before_stop}
    end
  end
end