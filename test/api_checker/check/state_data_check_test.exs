defmodule ApiChecker.Check.StaleDataCheckTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ApiChecker.Check.{StaleDataCheck, Params}
  alias ApiChecker.PreviousResponse
  import ApiChecker.TestHelpers

  describe "is_old_enough_to_be_stale?/3" do
    test "true for diff that is greater than the limit" do
      modified_at = datetime("2018-02-28T19:00:00Z")
      at_time = datetime("2018-02-28T19:05:00Z")
      # 1 second
      limit = 1
      assert StaleDataCheck.is_old_enough_to_be_stale?(limit, modified_at, at_time)
    end

    test "false for diff that is less than the limit" do
      modified_at = datetime("2018-02-28T19:00:00Z")
      at_time = datetime("2018-02-28T19:05:00Z")
      # 10 minutes
      limit = 600
      refute StaleDataCheck.is_old_enough_to_be_stale?(limit, modified_at, at_time)
    end

    test "works for StaleDataCheck struct and PreviousResponse struct" do
      stale_check = %StaleDataCheck{time_limit_in_seconds: 1}
      prev = %PreviousResponse{modified_at: datetime("2018-02-28T19:00:00Z")}
      at_time = datetime("2018-02-28T19:05:00Z")
      assert StaleDataCheck.is_old_enough_to_be_stale?(stale_check, prev, at_time)
    end
  end

  describe "run_check/2" do
    test "should be ok when there is no previous response" do
      stale_check = %StaleDataCheck{time_limit_in_seconds: 1}

      params = %Params{
        previous_response: nil
      }

      assert StaleDataCheck.run_check(stale_check, params) == :ok
    end

    test "should be ok when data is too recent to be stale" do
      stale_check = %StaleDataCheck{time_limit_in_seconds: 600}

      params = %Params{
        raw_body: "123",
        previous_response: %PreviousResponse{
          modified_at: datetime("2018-02-28T19:00:00Z"),
          body: "123"
        },
        check_time: datetime("2018-02-28T19:05:00Z")
      }

      assert StaleDataCheck.run_check(stale_check, params) == :ok
    end

    test "should return stale data error when data has not changed and limit has passed" do
      stale_check = %StaleDataCheck{time_limit_in_seconds: 1}

      params = %Params{
        raw_body: "123",
        previous_response: %PreviousResponse{
          modified_at: datetime("2018-02-28T19:00:00Z"),
          body: "123"
        },
        check_time: datetime("2018-02-28T19:05:00Z")
      }

      assert StaleDataCheck.run_check(stale_check, params) == {:error, :stale_data}
    end

    test "should be ok when response bodies are different" do
      stale_check = %StaleDataCheck{time_limit_in_seconds: 1}

      params = %Params{
        raw_body: "123",
        previous_response: %PreviousResponse{
          modified_at: datetime("2018-02-28T19:00:00Z"),
          body: "something different"
        },
        check_time: datetime("2018-02-28T19:05:00Z")
      }

      assert StaleDataCheck.run_check(stale_check, params) == :ok
    end
  end
end
