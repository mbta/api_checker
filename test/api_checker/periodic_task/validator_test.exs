defmodule ApiChecker.PeriodicTask.ValidatorTest do
  use ExUnit.Case, async: true
  alias ApiChecker.PeriodicTask
  alias ApiChecker.PeriodicTask.{Validator, TimeRange}
  doctest ApiChecker.PeriodicTask.Validator

  @valid_time_range %TimeRange{
    start: ~T[06:30:00],
    stop: ~T[07:40:00],
  }

  @valid_struct %PeriodicTask{
    frequency_in_seconds: 120,
    name: "valid-periodic-task-validator-test",
    url: "http://google.com",
    days_to_call: ["WED"],
    list_of_time_range: [@valid_time_range],
    data_age_limit: 300,
    active: true,
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
        days_to_call: [],
        days_to_call: ["wed"],
        days_to_call: ["WED", "foo"],
        days_to_call: nil,
        list_of_time_range: [],
        list_of_time_range: ["foo"],
        list_of_time_range: [@valid_time_range, "foo"],
        
      ]
      for {key, invalid_value} <- invalid_values do
        assert {:error, _reason} = @valid_struct |> Map.put(key, invalid_value) |> Validator.validate
      end
  
    end
  end

end