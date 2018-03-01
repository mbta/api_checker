defmodule ApiChecker.PeriodicTask.WeeklyTimeRangeTest do
  use ExUnit.Case, async: true
  alias ApiChecker.PeriodicTask
  alias ApiChecker.PeriodicTask.WeeklyTimeRange
  doctest ApiChecker.PeriodicTask.WeeklyTimeRange
  import ApiChecker.TestHelpers

  @thursday_6am_to_10pm %WeeklyTimeRange{
    start: ~T[06:00:00],
    stop: ~T[22:00:00],
    day: "THU"
  }

  @wednesday_12pm datetime("2018-02-28T12:00:00-0500")
  @thursday_1am datetime("2018-03-01T01:00:00-0500")
  @thursday_6am datetime("2018-03-01T06:00:00-0500")
  @thursday_12pm datetime("2018-03-01T12:00:00-0500")
  @thursday_10pm datetime("2018-03-01T22:00:00-0500")
  @thursday_11pm datetime("2018-03-01T23:00:00-0500")

  describe "intersects?/1" do
    test "returns true when a datetime is in range" do
      datetime = @thursday_12pm
      assert PeriodicTask.Days.name_of_day(datetime) == "THU"
      assert WeeklyTimeRange.intersects?(@thursday_6am_to_10pm, datetime)
    end

    test "returns false when a datetime's day is not the range's day" do
      datetime = @wednesday_12pm
      assert PeriodicTask.Days.name_of_day(datetime) == "WED"
      refute WeeklyTimeRange.intersects?(@thursday_6am_to_10pm, datetime)
    end

    test "returns false when a datetime's time is too early" do
      datetime = @thursday_1am
      assert PeriodicTask.Days.name_of_day(datetime) == "THU"
      refute WeeklyTimeRange.intersects?(@thursday_6am_to_10pm, datetime)
    end

    test "returns false when a datetime's time is too late" do
      datetime = @thursday_11pm
      assert PeriodicTask.Days.name_of_day(datetime) == "THU"
      refute WeeklyTimeRange.intersects?(@thursday_6am_to_10pm, datetime)
    end

    test "returns false when a datetime's time is exactly the start time" do
      datetime = @thursday_6am
      assert PeriodicTask.Days.name_of_day(datetime) == "THU"
      assert @thursday_6am_to_10pm.start == DateTime.to_time(datetime)
      assert WeeklyTimeRange.intersects?(@thursday_6am_to_10pm, datetime)
    end

    test "returns false when a datetime's time is exactly the stop time" do
      datetime = @thursday_10pm
      assert PeriodicTask.Days.name_of_day(datetime) == "THU"
      assert @thursday_6am_to_10pm.stop == DateTime.to_time(datetime)
      assert WeeklyTimeRange.intersects?(@thursday_6am_to_10pm, datetime)
    end
  end
end
