defmodule ApiChecker.PeriodicTaskTest do
  use ExUnit.Case
  alias ApiChecker.{PeriodicTask, JsonCheck}
  alias ApiChecker.PeriodicTask.{WeeklyTimeRange}
  doctest ApiChecker.PeriodicTask
  import ApiChecker.TestHelpers

  @valid_periodic_task_json %{
    "name" => "mbta-testing-01",
    "url" => "https://api-v3.mbta.com/predictions?filter%5Broute%5D=Red,Orange,Blue",
    "active" => true,
    "frequency_in_seconds" => 120,
    "time_ranges" => [
      %{"type" => "weekly", "day" => "MON", "start" => "06:30", "stop" => "22:00"},
      %{"type" => "weekly", "day" => "TUE", "start" => "06:30", "stop" => "22:00"},
      %{"type" => "weekly", "day" => "WED", "start" => "06:30", "stop" => "22:00"},
      %{"type" => "weekly", "day" => "THU", "start" => "06:30", "stop" => "22:00"},
      %{"type" => "weekly", "day" => "FRI", "start" => "06:30", "stop" => "22:00"}
    ],
    "checks" => [
      %{"keypath" => ["data"], "expects" => ["array", "not_empty"]},
      %{"keypath" => ["jsonapi"], "expects" => "jsonapi"}
    ]
  }

  describe "from_json/1" do
    test "works for valid json" do
      assert {:ok, task} = PeriodicTask.from_json(@valid_periodic_task_json)

      assert task.checks == [
               %JsonCheck{keypath: ["data"], expects: ["array", "not_empty"]},
               %JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"}
             ]

      assert task.time_ranges == [
               %WeeklyTimeRange{day: "MON", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %WeeklyTimeRange{day: "TUE", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %WeeklyTimeRange{day: "WED", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %WeeklyTimeRange{day: "THU", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %WeeklyTimeRange{day: "FRI", start: ~T[06:30:00], stop: ~T[22:00:00]}
             ]

      assert task.name == "mbta-testing-01"
      assert task.url == "https://api-v3.mbta.com/predictions?filter%5Broute%5D=Red,Orange,Blue"
      assert task.active == true
      assert task.frequency_in_seconds == 120
    end

    test "errors for invalid json" do
      assert {:error, _} = @valid_periodic_task_json |> Map.drop(["checks"]) |> PeriodicTask.from_json()
    end
  end

  @valid_periodic_task %PeriodicTask{
    name: "mbta-testing-01",
    url: "https://api-v3.mbta.com/predictions?filter%5Broute%5D=Red,Orange,Blue",
    active: true,
    frequency_in_seconds: 120,
    checks: [
      %JsonCheck{keypath: ["data"], expects: ["array", "not_empty"]},
      %JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"}
    ],
    time_ranges: [
      %WeeklyTimeRange{day: "MON", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "TUE", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "WED", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "THU", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "FRI", start: ~T[06:30:00], stop: ~T[22:00:00]}
    ]
  }

  @wednesday_12pm datetime("2018-02-28T12:00:00-0500")
  @thursday_1am datetime("2018-03-01T01:00:00-0500")
  @thursday_6am datetime("2018-03-01T06:00:00-0500")
  @thursday_12pm datetime("2018-03-01T12:00:00-0500")
  @thursday_10pm datetime("2018-03-01T22:00:00-0500")
  @thursday_11pm datetime("2018-03-01T23:00:00-0500")
  @saturday_12pm datetime("2018-03-03T12:00:00-0500")

  describe "intersects/2" do
    test "true for in range and" do
      task = @valid_periodic_task
      assert PeriodicTask.intersects?(task, @wednesday_12pm)
      assert PeriodicTask.intersects?(task, @thursday_12pm)
      assert PeriodicTask.intersects?(task, @thursday_10pm)
    end

    test "false when out of range" do
      task = @valid_periodic_task
      # too late
      refute PeriodicTask.intersects?(task, @thursday_11pm)
      # too early
      refute PeriodicTask.intersects?(task, @thursday_6am)
      # way too early
      refute PeriodicTask.intersects?(task, @thursday_1am)
      # wrong day
      refute PeriodicTask.intersects?(task, @saturday_12pm)
    end
  end
end
