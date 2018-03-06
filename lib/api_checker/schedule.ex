defmodule ApiChecker.Schedule do
  @moduledoc """
  Keeps track of the scheduled tasks.
  """

  alias ApiChecker.PeriodicTask

  @env_var "API_CHECKER_CONFIGURATION"

  def get_tasks!() do
    @env_var
    |> load_env_var!
    |> decode_json!
    |> to_periodic_tasks!
  end

  defp load_env_var!(varname) do
    case System.get_env(varname) do
      nil ->
        raise "ApiChecker Configuration Error - #{inspect(@env_var)} must be set in the environment."
      json when is_binary(json) ->
        json
    end
  end

  defp decode_json!(json) do
    case Jason.decode(json) do
      {:ok, config} ->
        config
      {:error, _} ->
        raise "ApiChecker Configuration Error - #{inspect(@env_var)} must be valid json."
    end
  end

  defp to_periodic_tasks!(checks) do
    checks
    |> Enum.with_index
    |> Enum.map(fn {check, index} -> periodic_task_from_json_config!(check, index) end)
  end

  defp periodic_task_from_json_config!(config, index) do
    case PeriodicTask.from_json(config) do
      {:ok, periodic_task} ->
        periodic_task
      {:error, _} ->
        raise "ApiChecker Configuration Error - the task at index #{index} was not valid." 
    end
  end
end
