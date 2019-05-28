defmodule ApiChecker.HolidayTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ApiChecker.Holiday

  @holiday_date ~D[2019-05-27]
  @regular_date ~D[2019-05-28]

  describe "is_holiday?/1" do
    test "returns true for holidays" do
      assert is_holiday?(@holiday_date)
    end

    test "returns false for non holidays" do
      refute is_holiday?(@regular_date)
    end
  end
end
