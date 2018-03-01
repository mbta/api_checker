defmodule ApiChecker.PeriodicTaskTest do
  use ExUnit.Case
  alias ApiChecker.{PeriodicTask, JsonCheck}
  doctest ApiChecker.PeriodicTask

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
               %ApiChecker.PeriodicTask.WeeklyTimeRange{day: "MON", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %ApiChecker.PeriodicTask.WeeklyTimeRange{day: "TUE", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %ApiChecker.PeriodicTask.WeeklyTimeRange{day: "WED", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %ApiChecker.PeriodicTask.WeeklyTimeRange{day: "THU", start: ~T[06:30:00], stop: ~T[22:00:00]},
               %ApiChecker.PeriodicTask.WeeklyTimeRange{day: "FRI", start: ~T[06:30:00], stop: ~T[22:00:00]}
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
end
