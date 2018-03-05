defmodule ApiChecker.PeriodicTask do
  @moduledoc """
  Provides context, parsing, validating for configuration of
  a PeriodicTask with the intention of configuring a worker process.
  """
  alias ApiChecker.{PeriodicTask, Check}
  alias ApiChecker.PeriodicTask.{WeeklyTimeRange, Times}

  defstruct frequency_in_seconds: nil,
            time_ranges: [],
            name: nil,
            url: nil,
            active: nil,
            checks: []

  @doc """
  Parses valid perodic task json into a PeriodicTask struct.
  """
  def from_json(json) do
    with {:ok, task} <- do_from_json(json),
         :ok <- validate(task) do
      {:ok, task}
    end
  end

  defp do_from_json(json) do
    with time_ranges when is_list(time_ranges) <- parse_time_ranges(json["time_ranges"]),
         checks when is_list(checks) <- parse_checks(json["checks"]) do
      {:ok,
       %PeriodicTask{
         frequency_in_seconds: json["frequency_in_seconds"],
         time_ranges: time_ranges,
         name: json["name"],
         url: json["url"],
         active: true,
         checks: checks
       }}
    else
      {:error, _} = err ->
        err
    end
  end

  def validate(%PeriodicTask{} = task) do
    PeriodicTask.Validator.validate(task)
  end

  defp parse_checks(json) when is_list(json) do
    Enum.map(json, &json_config_to_json_check/1)
  end

  defp parse_checks(_) do
    {:error, :checks_must_be_a_list}
  end

  defp parse_time_ranges(json) when is_list(json) do
    Enum.map(json, &json_to_time_range/1)
  end

  defp parse_time_ranges(_) do
    {:error, :time_ranges_must_be_a_list}
  end

  defp json_to_time_range(json) when is_map(json) do
    with {:ok, module} <- get_range_module(json),
         {:ok, new_range_struct} <- module.from_json(json) do
      new_range_struct
    else
      {:error, _} = err ->
        err
    end
  end

  defp json_to_time_range(_) do
    {:error, :invalid_time_range}
  end

  def json_config_to_json_check(json) when is_map(json) do
    case Check.from_json(json) do
      {:ok, json_check} ->
        json_check

      {:error, _} = err ->
        err
    end
  end

  def json_config_to_json_check(_) do
    {:error, :invalid_json_check_config}
  end

  def get_range_module(%{"type" => type}) do
    get_range_module(type)
  end

  def get_range_module("weekly") do
    {:ok, PeriodicTask.WeeklyTimeRange}
  end

  def get_range_module(_) do
    {:error, :invalid_range_type}
  end

  @doc """
  Given a `PeriodicTask` struct and a `DateTime` struct, returns true if the
  `datetime` falls within any of the periodic task's time ranges. False
  otherwise.
  """
  def intersects?(%PeriodicTask{time_ranges: ranges}, %DateTime{} = datetime) do
    Enum.any?(ranges, fn %WeeklyTimeRange{} = timerange -> WeeklyTimeRange.intersects?(timerange, datetime) end)
  end

  @doc """
  Given a datetime, returns true when the `PreviousResponse` struct's
  `updated_at` happened less than `frequency_in_seconds` ago. False otherwise.
  """
  def too_soon_to_run?(%PeriodicTask{} = periodic_task, %DateTime{} = previous_datetime, %DateTime{} = target_datetime) do
    previous_datetime = Times.to_service_timezone(previous_datetime)
    target_datetime = Times.to_service_timezone(target_datetime)
    # `difference` is a positive number when the target datetime is ahead of the
    # previous datetime.
    difference = DateTime.diff(target_datetime, previous_datetime)
    difference <= periodic_task.frequency_in_seconds
  end
end

# reject if it's too soon to run
