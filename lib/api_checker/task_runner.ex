defmodule ApiChecker.TaskRunner do
  require Logger
  alias ApiChecker.{PeriodicTask, PreviousResponse, Check}
  alias ApiChecker.Check.Params

  @doc """
  Runs tasks and updates `PreviousResponse` state with task results.
  """
  def perform(tasks, previous_responses) when is_list(tasks) and is_map(previous_responses) do
    task_results =
      Enum.map(tasks, fn task ->
        prev = Map.get(previous_responses, task.name)
        perform(task, prev)
      end)

    update_previous_responses(task_results)
    task_results
  end

  @doc """
  Runs checks for given `PeriodicTask` struct. Logs if checks don't meet
  expectation. Returns task and new `PreviousResponse` struct.
  """
  def perform(%PeriodicTask{} = task, previous_response) do
    {status_code, body} =
      case HTTPoison.get(task.url) do
        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          run_checks(task, body, previous_response)
          {status, body}

        {:error, %HTTPoison.Error{reason: reason}} ->
          Logger.info(fn -> "HTTP Error - task_name=#{inspect(task.name)} reason=#{inspect(reason)}" end)
          {nil, nil}
      end

    %{
      task: task,
      previous_response: %PreviousResponse{
        updated_at: DateTime.utc_now(),
        body: body,
        status_code: status_code
      }
    }
  end

  defp update_previous_responses(task_results) do
    previous_responses =
      Enum.reduce(task_results, %{}, fn task_result, acc ->
        Map.put(acc, task_result.task.name, task_result.previous_response)
      end)

    PreviousResponse.upsert(previous_responses)
  end

  defp run_checks(%PeriodicTask{checks: checks, name: name}, raw_body, previous_response) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, decoded_body} ->
        params = %Params{
          raw_body: raw_body,
          decoded_body: decoded_body,
          name: name,
          check_time: DateTime.utc_now(),
          previous_response: previous_response
        }

        run_checks(checks, params)

      {:error, _} = err ->
        Logger.info(fn -> "JSON Decoding Error - task_name=#{inspect(name)} error=#{inspect(err)}" end)
        err
    end
  end

  defp run_checks(checks, %Params{} = params) when is_list(checks) do
    for check <- checks do
      run_check(check, params)
    end
  end

  def run_check(check, %Params{} = params) do
    case Check.run_check(check, params) do
      :ok ->
        Logger.info(fn -> "Check OK - task_name=#{inspect(params.name)} check=#{inspect(check)}" end)
        :ok

      {:error, reason} = err ->
        Logger.info(fn ->
          "Check Failure - task_name=#{inspect(params.name)} check=#{inspect(check)} reason=#{
            reason |> to_string() |> inspect()
          }"
        end)

        err
    end
  end
end
