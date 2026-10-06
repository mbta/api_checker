defmodule ApiChecker.TaskRunnerTest do
  use ExUnit.Case, async: false
  alias ApiChecker.Check.JsonCheck
  alias ApiChecker.{PeriodicTask, PreviousResponse, TaskRunner}
  import ExUnit.CaptureLog

  @valid_periodic_task %PeriodicTask{
    name: "mbta-testing-01",
    url: "https://api-v3.mbta.com/predictions?filter%5Broute%5D=Red,Orange,Blue",
    checks: [
      %JsonCheck{keypath: ["data"], expects: "not_empty"},
      %JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"}
    ]
  }

  @failure_periodic_task %PeriodicTask{
    name: "failure-task",
    url: "https://api-v3.mbta.com/predictions?filter%5Broute%5D=Red,Orange,Blue",
    checks: [
      %JsonCheck{keypath: ["unexpected"], expects: "not_empty"},
      %JsonCheck{keypath: ["data"], expects: %{"expectation" => "min_length", "min_length" => 20_000}}
    ]
  }

  describe "perform/1" do
    test "can run one task with multiple checks" do
      captured =
        capture_log(fn ->
          %{previous_response: previous_response} = TaskRunner.perform(@valid_periodic_task, %PreviousResponse{})
          assert previous_response.updated_at == previous_response.modified_at
        end)

      assert captured =~ ~s(Check OK)
      assert captured =~ ~s(task_name="mbta-testing-01")
      assert captured =~ ~s(%ApiChecker.Check.JsonCheck{keypath: ["data"], expects: "not_empty"})
      assert captured =~ ~s(length=)
      assert captured =~ ~s(%ApiChecker.Check.JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"})
    end

    test "logs failure for failed check" do
      captured = capture_log(fn -> TaskRunner.perform(@failure_periodic_task, %PreviousResponse{}) end)
      assert captured =~ ~s(Check Failure)
      assert captured =~ ~s(task_name="failure-task")
      assert captured =~ ~s(%ApiChecker.Check.JsonCheck{keypath: ["unexpected"], expects: "not_empty"})
      assert captured =~ ~s(reason=:invalid_array)
      assert captured =~ ~s(length=)
      assert captured =~ ~s(reason=:array_too_small)
    end

    @tag :capture_log
    test "doesn't update `modified_at` if the data is the same as last time" do
      now = DateTime.from_unix!(0)

      previous_response = %PreviousResponse{
        updated_at: now,
        modified_at: now,
        status_code: 200,
        body: "hello world"
      }

      task = %PeriodicTask{
        name: "hello-world-task",
        url: "https://httpbin.org/base64/aGVsbG8gd29ybGQ=",
        checks: []
      }

      %{previous_response: new_response} = TaskRunner.perform(task, previous_response)
      refute new_response.updated_at == previous_response.updated_at
      assert new_response.modified_at == previous_response.modified_at
    end
  end

  test "can run one multiple tasks" do
    captured =
      capture_log(fn -> TaskRunner.perform([@valid_periodic_task, @failure_periodic_task], %PreviousResponse{}) end)

    assert captured =~ ~s(Check OK - task_name="mbta-testing-01")
    assert captured =~ ~s(Check Failure - task_name="failure-task")
  end

  describe "run_check/2 CloudEvent publishing" do
    defmodule RecordingClient do
      @moduledoc false
      @behaviour ApiChecker.Events.KinesisClient

      @impl true
      def publish_event(stream_name, partition_key, data) do
        test_pid = Application.fetch_env!(:api_checker, :kinesis_test_pid)
        send(test_pid, {:publish_event, stream_name, partition_key, data})
        :ok
      end
    end

    setup do
      original_client = Application.get_env(:api_checker, :kinesis_client)
      original_stream_name = Application.get_env(:api_checker, :kinesis_stream_name)

      Application.put_env(:api_checker, :kinesis_client, RecordingClient)
      Application.put_env(:api_checker, :kinesis_stream_name, "my-stream")
      Application.put_env(:api_checker, :kinesis_test_pid, self())

      on_exit(fn ->
        Application.put_env(:api_checker, :kinesis_client, original_client)
        Application.put_env(:api_checker, :kinesis_stream_name, original_stream_name)
        Application.delete_env(:api_checker, :kinesis_test_pid)
      end)

      :ok
    end

    test "publishes a successful check event for each check that runs" do
      params = %ApiChecker.Check.Params{
        decoded_body: %{"data" => ["ok"], "jsonapi" => %{"version" => "1.0"}},
        name: "mbta-testing-01"
      }

      for check <- @valid_periodic_task.checks do
        TaskRunner.run_check(check, params)
      end

      assert_receive {:publish_event, "my-stream", "mbta-testing-01", data}
      assert {:ok, %{"data" => %{"checkName" => "mbta-testing-01", "success" => true}}} = Jason.decode(data)
      assert_receive {:publish_event, "my-stream", "mbta-testing-01", _data}
    end

    test "publishes a failing check event when a check fails" do
      params = %ApiChecker.Check.Params{decoded_body: %{}, name: "failure-task"}
      check = %JsonCheck{keypath: ["unexpected"], expects: "not_empty"}

      TaskRunner.run_check(check, params)

      assert_receive {:publish_event, "my-stream", "failure-task", data}
      assert {:ok, %{"data" => %{"checkName" => "failure-task", "success" => false}}} = Jason.decode(data)
    end
  end
end
