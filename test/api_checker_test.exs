defmodule ApiCheckerTest do
  use ExUnit.Case, async: true
  alias ApiChecker.PeriodicTask.WeeklyTimeRange
  alias ApiChecker.{PeriodicTask, JsonCheck, PreviousResponse}
  import ApiChecker.TestHelpers
  doctest ApiChecker

  @periodic_task_1 %PeriodicTask{
    name: "mbta-testing-01",
    url: "https://api-v3.mbta.com/predictions?filter%5Broute%5D=Red,Orange,Blue",
    active: true,
    frequency_in_seconds: 120,
    checks: [
      %JsonCheck{keypath: ["data"], expects: ["array", "not_empty"]},
    ],
    time_ranges: [
      %WeeklyTimeRange{day: "MON", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "TUE", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "WED", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "THU", start: ~T[06:30:00], stop: ~T[22:00:00]},
      %WeeklyTimeRange{day: "FRI", start: ~T[06:30:00], stop: ~T[22:00:00]}
    ]
  }

  @periodic_task_2 %PeriodicTask{
    name: "mbta-testing-02",
    url: "http://realtime.mbta.com/developer/api/v2/vehiclesbyroutes?format=json&routes=1",
    active: true,
    frequency_in_seconds: 120,
    checks: [
      %JsonCheck{keypath: ["data"], expects: ["array", "not_empty"]},
    ],
    time_ranges: [
      %WeeklyTimeRange{day: "SAT", start: ~T[06:30:00], stop: ~T[22:00:00]},
    ]
  }

  @periodic_task_3 %PeriodicTask{
    name: "mbta-testing-03",
    url: "http://realtime.mbta.com/developer/api/v2/vehicles",
    active: true,
    frequency_in_seconds: 120,
    checks: [
      %JsonCheck{keypath: ["data"], expects: ["array", "not_empty"]},
    ],
    time_ranges: [
      %WeeklyTimeRange{day: "THU", start: ~T[06:30:00], stop: ~T[22:00:00]},
    ]
  }

  @tasks [
    @periodic_task_1, 
    @periodic_task_2, 
    @periodic_task_3
  ]

  @thursday_12pm datetime("2018-03-01T12:00:00-0500")
  @thursday_12_01pm datetime("2018-03-01T12:01:00-0500")
  @thursday_12_05pm datetime("2018-03-01T12:05:00-0500")
  @sunday_12pm datetime("2018-03-04T12:00:00-0500")

  @previous_responses %{
    "mbta-testing-01" => %PreviousResponse{updated_at: @thursday_12pm},
    "mbta-testing-02" => %PreviousResponse{updated_at: @thursday_12pm},
  }

  describe "tasks_due/0" do
    test "with tasks due for given datetime" do
      target_datetime = @thursday_12_05pm
      tasks_due = ApiChecker.tasks_due(@tasks, @previous_responses, target_datetime)
      # `@periodic_task_1` runs every weekday and previous response happened
      # more than `frequency_in_seconds` ago
      assert @periodic_task_1 in tasks_due
      # `@periodic_task_3` runs every THU and has no previous response
      assert @periodic_task_3 in tasks_due
    end

    test "rejects tasks for the wrong day" do
      # no tasks are configure to run on SUN
      target_datetime = @sunday_12pm
      tasks_due = ApiChecker.tasks_due(@tasks, @previous_responses, target_datetime)
      assert tasks_due == []
    end

    test "does not reject tasks that are intersected but not in previous responses" do
      # on THU at 12:05pm `@periodic_task_3` interesects and does not have a
      # previous reponse so it's due to run
      target_datetime = @thursday_12_05pm
      tasks_due = ApiChecker.tasks_due(@tasks, @previous_responses, target_datetime)
      assert @periodic_task_3 in tasks_due
    end

    test "rejects tasks that are too soon to run" do
      target_datetime = @thursday_12_01pm
      tasks_due = ApiChecker.tasks_due(@tasks, @previous_responses, target_datetime)
      # Previous responses for `@periodic_task_1` and `@periodic_task_2`
      # happened on THU at 12:00pm. They are configured to run every 120
      # seconds so they would not be due to run at 12:01pm.
      refute @periodic_task_1 in tasks_due
      refute @periodic_task_2 in tasks_due
    end
  end
end
