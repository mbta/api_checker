defmodule ApiChecker.PeriodicTask do
  @moduledoc """
  Provides context, parsing, validating for configuration of
  a PeriodicTask with the intention of configuring a worker process.
  """
  alias ApiChecker.{PeriodicTask, ApiValidator}

  defstruct frequency_in_seconds: nil,
            time_ranges: [],
            name: nil,
            url: nil,
            active: nil,
            validators: []

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
         validators when is_list(validators) <- parse_validators(json["validators"]) do
      {:ok,
       %PeriodicTask{
         frequency_in_seconds: json["frequency_in_seconds"],
         time_ranges: time_ranges,
         name: json["name"],
         url: json["url"],
         active: true,
         validators: validators
       }}
    else
      {:error, _} = err ->
        err
    end
  end

  def validate(%PeriodicTask{} = task) do
    PeriodicTask.Validator.validate(task)
  end

  defp parse_validators(json) when is_list(json) do
    Enum.map(json, &json_to_validator/1)
  end

  defp parse_validators(_) do
    {:error, :validators_must_be_a_list}
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

  def json_to_validator(json) when is_map(json) do
    case ApiValidator.from_json(json) do
      {:ok, api_validator} ->
        api_validator

      {:error, _} = err ->
        err
    end
  end

  def json_to_validator(_) do
    {:error, :invalid_validator_config}
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
end
