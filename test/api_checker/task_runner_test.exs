defmodule ApiChecker.TaskRunnerTest do
  use ExUnit.Case, async: true
  alias ApiChecker.{TaskRunner, PeriodicTask, PreviousResponse}
  alias ApiChecker.Check.JsonCheck
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
      %JsonCheck{keypath: ["unexpected"], expects: "not_empty"}
    ]
  }

  describe "perform/1" do
    test "can run one task with multiple checks" do
      captured = capture_log(fn -> TaskRunner.perform(@valid_periodic_task, %PreviousResponse{}) end)
      assert captured =~ ~s(Check OK)
      assert captured =~ ~s(task_name="mbta-testing-01")
      assert captured =~ ~s(%ApiChecker.Check.JsonCheck{expects: "not_empty", keypath: ["data"]})
      assert captured =~ ~s(%ApiChecker.Check.JsonCheck{expects: "jsonapi", keypath: ["jsonapi"]})
    end

    test "logs failure for failed check" do
      captured = capture_log(fn -> TaskRunner.perform(@failure_periodic_task, %PreviousResponse{}) end)
      assert captured =~ ~s(Check Failure)
      assert captured =~ ~s(task_name="failure-task")
      assert captured =~ ~s(%ApiChecker.Check.JsonCheck{expects: "not_empty", keypath: ["unexpected"]})
      assert captured =~ ~s(reason="invalid_array")
    end
  end

  test "can run one multiple tasks" do
    captured =
      capture_log(fn -> TaskRunner.perform([@valid_periodic_task, @failure_periodic_task], %PreviousResponse{}) end)

    assert captured =~ ~s(Check OK - task_name="mbta-testing-01")
    assert captured =~ ~s(Check Failure - task_name="failure-task")
  end
end
