defmodule ApiChecker.TaskRunner do
  require Logger
  alias ApiChecker.{PeriodicTask, PreviousResponse, JsonCheck}

  @doc """
  Runs tasks and updates `PreviousResponse` state with task results.
  """
  def perform(tasks) when is_list(tasks) do
    task_results = Enum.map(tasks, &perform/1)
    update_previous_responses(task_results)
    task_results
  end

  @doc """
  Runs checks for given `PeriodicTask` struct. Logs if checks don't meet
  expectation. Returns task and new `PreviousResponse` struct.
  """
  def perform(%PeriodicTask{} = task) do
    {status_code, body} =
      case HTTPoison.get(task.url) do
        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          run_checks(task, body)
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

  defp run_checks(task, body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded_body} ->
        run_checks(task, decoded_body)

      {:error, _} = err ->
        Logger.info(fn -> "JSON Decoding Error - task_name=#{inspect(task.name)} error=#{inspect(err)}" end)
        err
    end
  end

  defp run_checks(task, decoded_body) do
    for json_check <- task.checks do
      run_check(json_check, decoded_body, task)
    end
  end

  def run_check(json_check, decoded_body, task) do
    case JsonCheck.run_check(json_check, decoded_body) do
      :ok ->
        Logger.info(fn -> "Check OK - task_name=#{inspect(task.name)} check=#{inspect(json_check)}" end)
        :ok

      {:error, _} = err ->
        Logger.info(fn -> "Check Failure - task_name=#{inspect(task.name)} #{inspect(err)}" end)
        err
    end
  end
end
