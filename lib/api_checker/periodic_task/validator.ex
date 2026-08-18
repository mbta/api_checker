defmodule ApiChecker.PeriodicTask.Validator do
  @moduledoc """
  Validates a PeriodicTask struct's values.
  """
  alias ApiChecker.{Check, PeriodicTask}
  alias ApiChecker.PeriodicTask.WeeklyTimeRange

  @doc """
  Validates a PeriodicTask struct's values.

  :ok if valid, {:error, reason} if invalid.
  """
  def validate(%PeriodicTask{} = task) do
    with :ok <- run_validation(task, :frequency_in_seconds, &pos_integer?/1, "must be a positive integer"),
         :ok <- run_validation(task, :name, &is_binary/1, "must be a string"),
         :ok <- run_validation(task, :name, &not_blank?/1, "cannot be blank"),
         :ok <- run_validation(task, :url, &valid_url?/1, "must be a valid url"),
         :ok <- run_validation(task, :time_ranges, &list_of_time_ranges?/1, "must be a list of valid time ranges"),
         :ok <- run_validation(task, :checks, &list_of_checks?/1, "must be a list of valid checks") do
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

  iex> Validator.pos_integer?(1)
  true

  iex> Validator.pos_integer?(0)
  false

  iex> Validator.pos_integer?(nil)
  false
  """
  def pos_integer?(item) when is_integer(item) and item > 0 do
    true
  end

  def pos_integer?(_) do
    false
  end

  @doc """
  Returns false for items that are blank (`""` and `nil`) and returns true
  for anything else.

  iex> Validator.not_blank?("")
  false

  iex> Validator.not_blank?(nil)
  false

  iex> Validator.not_blank?("itemthing")
  true
  """
  def not_blank?(item), do: !blank?(item)

  @doc """
  Returns true for items that are blank (`""` and `nil`) and returns false
  for anything else.

  iex> Validator.blank?("")
  true

  iex> Validator.blank?(nil)
  true

  iex> Validator.blank?("itemthing")
  false
  """
  def blank?(""), do: true
  def blank?(nil), do: true
  def blank?(_), do: false

  @doc """
  A simple validation for url binaries.

  Returns true for well formatted URL strings and false for
  anything else.

  iex> Validator.valid_url?("http://realtime.mbta.com/developer/api/v2/vehiclesbyroutes")
  true

  iex> Validator.valid_url?("ftp://somthing.org:4444")
  false

  iex> Validator.valid_url?("http://")
  false
  """
  def valid_url?(url) when is_binary(url) do
    url
    |> URI.parse()
    |> valid_url?
  end

  def valid_url?(%URI{} = uri) do
    uri.scheme in ["https", "http"] and not_blank?(uri.host)
  end

  def valid_url?(_) do
    false
  end

  @doc """
  Returns true for a non-empty list of valid TimeRange structs.

  Returns false for anything else.

  iex> Validator.list_of_time_ranges?([])
  false

  iex> Validator.list_of_time_ranges?([%WeeklyTimeRange{start: ~T[06:30:00], stop: ~T[07:30:00], day: "SAT"}])
  true

  iex> Validator.list_of_time_ranges?([%WeeklyTimeRange{start: nil, stop: ~T[07:30:00]}])
  false
  """
  def list_of_time_ranges?([]) do
    false
  end

  def list_of_time_ranges?(list) when is_list(list) do
    Enum.all?(list, &time_range?/1)
  end

  def list_of_time_ranges?(_) do
    false
  end

  @doc """
  Returns true for a non-empty list of valid TimeRange structs.

  Returns false for anything else.

  iex> Validator.list_of_checks?([])
  false

  iex> Validator.list_of_checks?([%JsonCheck{expects: "not_empty"}])
  true

  iex> Validator.list_of_checks?([%JsonCheck{expects: "not_a_real_expectation"}])
  false
  """
  def list_of_checks?([]) do
    false
  end

  def list_of_checks?(list) when is_list(list) do
    Enum.all?(list, &check?/1)
  end

  def list_of_checks?(_) do
    false
  end

  def check?(thing) do
    Check.validate(thing) == :ok
  end

  @doc """
  Returns true for valid TimeRange structs and false for anything else.

  iex> Validator.time_range?(%WeeklyTimeRange{start: ~T[06:30:00], stop: ~T[07:30:00], day: "WED"})
  true

  iex> Validator.time_range?(%WeeklyTimeRange{start: nil, stop: ~T[07:30:00], day: "TUE"})
  false

  iex> Validator.time_range?(%WeeklyTimeRange{start: ~T[07:30:00], stop: ~T[07:30:00], day: "THU"})
  false
  """
  def time_range?(%WeeklyTimeRange{} = time_range) do
    WeeklyTimeRange.validate(time_range) == :ok
  end

  def time_range?(_) do
    false
  end

  defp run_validation(%PeriodicTask{} = task, field, bool_func, reason) when is_function(bool_func, 1) do
    if task |> Map.get(field) |> bool_func.() do
      :ok
    else
      {:error, reason_formatter(field, reason)}
    end
  end

  defp reason_formatter(field, description) do
    "'#{field}' #{description}"
  end
end
