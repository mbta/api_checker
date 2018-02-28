defmodule ApiChecker.PeriodicTask.ValidatorTest do
  use ExUnit.Case, async: true
  alias ApiChecker.PeriodicTask
  alias ApiChecker.PeriodicTask.{Validator, WeeklyTimeRange}
  doctest ApiChecker.PeriodicTask.Validator

  @valid_time_range %WeeklyTimeRange{
    start: ~T[06:30:00],
    stop: ~T[07:40:00],
    day: "WED"
  }

  @valid_struct %PeriodicTask{
    frequency_in_seconds: 120,
    name: "valid-periodic-task-validator-test",
    url: "http://google.com",
    time_ranges: [@valid_time_range],
    # data_age_limit: 300,
    active: true,
    validators: []
  }

  describe "validate/1" do
    test "ok for valid PeriodicTasks" do
      assert :ok == Validator.validate(@valid_struct)
    end

    test "error for non-PeriodicTask" do
      assert {:error, :not_a_periodic_task} == Validator.validate(nil)
    end

    test "error for invalid PeriodicTask" do
      invalid_values = [
        frequency_in_seconds: nil,
        frequency_in_seconds: -20,
        frequency_in_seconds: "20",
        name: 123,
        name: "",
        url: "http://",
        url: "foo",
        url: "//google.com/foo",
        time_ranges: [],
        time_ranges: ["foo"],
        time_ranges: [@valid_time_range, "foo"]
      ]

      for {key, invalid_value} <- invalid_values do
        assert {:error, _reason} = @valid_struct |> Map.put(key, invalid_value) |> Validator.validate()
      end
    end
  end
end
