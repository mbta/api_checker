defmodule ApiChecker.UtilitiesTest do
  use ExUnit.Case, async: true
  alias ApiChecker.Utilities
  doctest Utilities

  describe "service_date_and_gtfs_minutes/1" do
    test "returns current calendar date and wall-clock minutes for times at/after 4 AM" do
      dt = %DateTime{
        year: 2024,
        month: 6,
        day: 15,
        hour: 10,
        minute: 30,
        second: 0,
        time_zone: "America/New_York",
        zone_abbr: "EDT",
        utc_offset: -18_000,
        std_offset: 3600
      }

      assert {~D[2024-06-15], 630} = Utilities.service_date_and_gtfs_minutes(dt)
    end

    test "returns previous calendar date and GTFS time > 24:00 for times before 4 AM" do
      dt = %DateTime{
        year: 2024,
        month: 6,
        day: 15,
        hour: 1,
        minute: 30,
        second: 0,
        time_zone: "America/New_York",
        zone_abbr: "EDT",
        utc_offset: -18_000,
        std_offset: 3600
      }

      assert {~D[2024-06-14], 1530} = Utilities.service_date_and_gtfs_minutes(dt)
    end

    test "treats exactly 4 AM as the start of the current service day" do
      dt = %DateTime{
        year: 2024,
        month: 6,
        day: 15,
        hour: 4,
        minute: 0,
        second: 0,
        time_zone: "America/New_York",
        zone_abbr: "EDT",
        utc_offset: -18_000,
        std_offset: 3600
      }

      assert {~D[2024-06-15], 240} = Utilities.service_date_and_gtfs_minutes(dt)
    end

    test "handles month boundary correctly" do
      dt = %DateTime{
        year: 2024,
        month: 7,
        day: 1,
        hour: 2,
        minute: 0,
        second: 0,
        time_zone: "America/New_York",
        zone_abbr: "EDT",
        utc_offset: -18_000,
        std_offset: 3600
      }

      assert {~D[2024-06-30], 1560} = Utilities.service_date_and_gtfs_minutes(dt)
    end
  end

  describe "format_gtfs_time/1" do
    test "formats normal daytime hours" do
      assert "10:30" = Utilities.format_gtfs_time(10 * 60 + 30)
    end

    test "pads single-digit hours and minutes with zeros" do
      assert "04:05" = Utilities.format_gtfs_time(4 * 60 + 5)
    end

    test "formats times past midnight (> 24:00)" do
      assert "25:00" = Utilities.format_gtfs_time(25 * 60)
      assert "26:30" = Utilities.format_gtfs_time(26 * 60 + 30)
    end
  end
end
