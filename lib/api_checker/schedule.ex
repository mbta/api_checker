defmodule ApiChecker.Schedule do
  @moduledoc """
  Keeps track of the scheduled tasks.
  """
  require Logger
  alias ApiChecker.PeriodicTask

  @env_var "API_CHECKER_CONFIGURATION"

  def env_var, do: @env_var

  def get_tasks!() do
    @env_var
    |> load_env_var!
    |> decode_json!
    |> to_periodic_tasks!
  end

  defp load_env_var!(varname) do
    case System.get_env(varname) do
      data when data in [nil, ""] ->
        Logger.error(fn ->
          "ApiChecker Configuration Error - #{inspect(@env_var)} must be set in the environment."
        end)

        invalid_config_shutdown()

      json when is_binary(json) ->
        json
    end
  end

  defp decode_json!(json) do
    case Jason.decode(json) do
      {:ok, config} ->
        config

      {:error, _} ->
        Logger.error(fn ->
          "ApiChecker Configuration Error - #{inspect(@env_var)} must be valid json."
        end)

        invalid_config_shutdown()
    end
  end

  defp to_periodic_tasks!(checks) do
    checks
    |> Enum.with_index()
    |> Enum.flat_map(fn {check, index} -> periodic_task_from_json_config!(check, index) end)
  end

  defp periodic_task_from_json_config!(config, index) do
    case PeriodicTask.from_json(config) do
      {:ok, periodic_task} ->
        [periodic_task]

      {:error, :ignored} ->
        []

      {:error, _} ->
        Logger.error(fn ->
          "ApiChecker Configuration Error - the task at index #{index} was not valid."
        end)

        invalid_config_shutdown()
    end
  end

  def invalid_config_shutdown do
    Logger.error(fn ->
      """
      ApiChecker Configuration Error

      Invalid Configuration: please ensure the enviroment variable #{@env_var}
      is properly configured before restarting the application.

      ...Shutting Down...
      """
    end)

    System.stop()
    # prevents the supervision tree from restarting repeatedly during system stop.
    :timer.sleep(:infinity)
  end
end
