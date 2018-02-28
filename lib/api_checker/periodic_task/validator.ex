defmodule ApiChecker.PeriodicTask.Validator do
  @moduledoc """
  Validates a PeriodicTask struct's values.
  """
  alias ApiChecker.PeriodicTask
  alias ApiChecker.PeriodicTask.{TimeRange, Days}

  @doc """
  Validates a PeriodicTask struct's values.

  :ok if valid, {:error, reason} if invalid.
  """
  def validate(%PeriodicTask{} = task) do
    with :ok <- run_validation(task, :frequency_in_seconds, &is_pos_integer?/1, "must be a positive integer"),
         :ok <- run_validation(task, :name, &is_binary/1, "must be a string"),
         :ok <- run_validation(task, :name, &is_not_blank?/1, "cannot be blank"),
         :ok <- run_validation(task, :url, &is_valid_url?/1, "must be a valid url"),
         :ok <- run_validation(task, :days_to_call, &is_list_of_days_of_week?/1, "must be a list of days of the week"),
         :ok <-
           run_validation(task, :list_of_time_range, &is_list_of_time_ranges?/1, "must be a list of valid time ranges"),
         :ok <- run_validation(task, :data_age_limit, &is_pos_integer?/1, "must be a positive integer"),
         :ok <- run_validation(task, :active, &is_boolean/1, "must be a boolean") do
      :ok
    else
      {:error, _} = err ->
        err
    end
  end

  def validate(_) do
    {:error, :not_a_periodic_task}
  end

  @doc """
  Returns true for positive integers and false for anything else.

  iex> Validator.is_pos_integer?(1)
  true

  iex> Validator.is_pos_integer?(0)
  false

  iex> Validator.is_pos_integer?(nil)
  false
  """
  def is_pos_integer?(item) when is_integer(item) and item > 0 do
    true
  end

  def is_pos_integer?(_) do
    false
  end

  @doc """
  Returns false for items that are blank (`""` and `nil`) and returns true
  for anything else.

  iex> Validator.is_not_blank?("")
  false

  iex> Validator.is_not_blank?(nil)
  false

  iex> Validator.is_not_blank?("itemthing")
  true
  """
  def is_not_blank?(item), do: !is_blank?(item)

  @doc """
  Returns true for items that are blank (`""` and `nil`) and returns false
  for anything else.

  iex> Validator.is_blank?("")
  true

  iex> Validator.is_blank?(nil)
  true

  iex> Validator.is_blank?("itemthing")
  false
  """
  def is_blank?(""), do: true
  def is_blank?(nil), do: true
  def is_blank?(_), do: false

  @doc """
  A simple validation for url binaries.

  Returns true for well formatted URL strings and false for
  anything else.

  iex> Validator.is_valid_url?("http://realtime.mbta.com/developer/api/v2/vehiclesbyroutes")
  true

  iex> Validator.is_valid_url?("ftp://somthing.org:4444")
  false

  iex> Validator.is_valid_url?("http://")
  false
  """
  def is_valid_url?(url) when is_binary(url) do
    url
    |> URI.parse()
    |> is_valid_url?
  end

  def is_valid_url?(%URI{} = uri) do
    uri.scheme in ["https", "http"] and is_not_blank?(uri.host)
  end

  def is_valid_url?(_) do
    false
  end

  @doc """
  Returns true for capitalized three-lettered abbreviations for days of the week.
  Returns false for anything else.

  iex> Validator.is_day_of_week?("FRI")
  true

  iex> Validator.is_day_of_week?("fri")
  false

  iex> Validator.is_day_of_week?("DAY")
  false
  """
  def is_day_of_week?(day) do
    day in Days.names()
  end

  @doc """
  Returns true for a list of capitalized three-lettered abbreviations for days of the week.

  Returns false for anything else.

  iex> Validator.is_list_of_days_of_week?(["FRI", "SAT", "SUN", "MON", "TUE", "WED", "THU"])
  true

  iex> Validator.is_list_of_days_of_week?([])
  false

  iex> Validator.is_list_of_days_of_week?(["FRI"])
  true

  iex> Validator.is_list_of_days_of_week?(["friday"])
  false

  iex> Validator.is_list_of_days_of_week?("FRI")
  false
  """
  def is_list_of_days_of_week?([]) do
    false
  end

  def is_list_of_days_of_week?(list) when is_list(list) do
    Enum.all?(list, &is_day_of_week?/1)
  end

  def is_list_of_days_of_week?(_) do
    false
  end

  @doc """
  Returns true for a non-empty list of valid TimeRange structs.

  Returns false for anything else.

  iex> Validator.is_list_of_time_ranges?([])
  false

  iex> Validator.is_list_of_time_ranges?([%TimeRange{start: ~T[06:30:00], stop: ~T[07:30:00]}])
  true

  iex> Validator.is_list_of_time_ranges?([%TimeRange{start: nil, stop: ~T[07:30:00]}])
  false
  """
  def is_list_of_time_ranges?([]) do
    false
  end

  def is_list_of_time_ranges?(list) when is_list(list) do
    Enum.all?(list, &is_time_range?/1)
  end

  def is_list_of_time_ranges?(_) do
    false
  end

  @doc """
  Returns true for valid TimeRange structs and false for anything else.

  iex> Validator.is_time_range?(%TimeRange{start: ~T[06:30:00], stop: ~T[07:30:00]})
  true

  iex> Validator.is_time_range?(%TimeRange{start: nil, stop: ~T[07:30:00]})
  false

  iex> Validator.is_time_range?(%TimeRange{start: ~T[07:30:00], stop: ~T[07:30:00]})
  false
  """
  def is_time_range?(%TimeRange{} = time_range) do
    TimeRange.validate(time_range) == :ok
  end

  def is_time_range?(_) do
    false
  end

  defp run_validation(%PeriodicTask{} = task, field, bool_func, reason) when is_function(bool_func, 1) do
    found = Map.get(task, field)

    if bool_func.(found) do
      :ok
    else
      {:error, reason_formatter(field, reason)}
    end
  end

  defp reason_formatter(field, description) do
    "'#{field}' #{description}"
  end
end
