defmodule ApiChecker.Check.JsonCheckTest do
  use ExUnit.Case, async: false
  alias ApiChecker.Check.{JsonCheck, Params}
  alias JsonCheck.{Array, Jsonapi}
  doctest JsonCheck

  describe "from_json/1" do
    test "valid json is turned into a struct as expected and is run_check-able" do
      valid_json = %{
        "keypath" => "jsonapi",
        "expects" => "jsonapi"
      }

      assert {:ok, json_check} = JsonCheck.from_json(valid_json)
      assert json_check.keypath == ["jsonapi"]
      assert json_check.expects == "jsonapi"

      valid_json = %{
        "jsonapi" => %{
          "version" => "1.0"
        }
      }

      invalid_json1 = %{
        "jsonapi" => %{
          "not_version" => "1.0"
        }
      }

      invalid_json2 = %{
        "not_jsonapi" => %{
          "version" => "1.0"
        }
      }

      params = %Params{decoded_body: valid_json}
      invalid_params1 = %Params{decoded_body: invalid_json1}
      invalid_params2 = %Params{decoded_body: invalid_json2}

      assert :ok = JsonCheck.run_check(json_check, params)
      assert {:error, _} = JsonCheck.run_check(json_check, invalid_params1)
      assert {:error, _} = JsonCheck.run_check(json_check, invalid_params2)
    end

    test "can handle expectations which are objects" do
      valid_json = %{
        "expects" => %{
          "expectation" => "min_length",
          "min_length" => 2
        }
      }

      assert {:ok, json_check} = JsonCheck.from_json(valid_json)

      valid_params = %Params{decoded_body: [1, 2]}
      invalid_params = %Params{decoded_body: [1]}
      assert {:ok, length: 2} = JsonCheck.run_check(json_check, valid_params)
      assert {:error, _, _} = JsonCheck.run_check(json_check, invalid_params)
    end
  end

  describe "active_trip_min_length expectation" do
    setup do
      bypass = Bypass.open()
      Application.put_env(:api_checker, :trip_count_base_url, "http://localhost:#{bypass.port}")
      on_exit(fn -> Application.delete_env(:api_checker, :trip_count_base_url) end)
      %{bypass: bypass}
    end

    test "passes when response length >= floor(trip_count * multiplier)", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        body = Jason.encode!(%{"data" => Enum.map(1..10, &%{"id" => "t#{&1}"})})
        Plug.Conn.resp(conn, 200, body)
      end)

      check_json = %{
        "expects" => %{
          "expectation" => "active_trip_min_length",
          "routes" => ["jc-pass-route"],
          "multiplier" => 0.5
        }
      }

      assert {:ok, json_check} = JsonCheck.from_json(check_json)
      # 10 trips * 0.5 = 5 minimum; providing 5 items
      params = %Params{decoded_body: Enum.map(1..5, &%{"id" => &1})}
      assert {:ok, length: 5} = JsonCheck.run_check(json_check, params)
    end

    test "fails when response length < floor(trip_count * multiplier)", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        body = Jason.encode!(%{"data" => Enum.map(1..10, &%{"id" => "t#{&1}"})})
        Plug.Conn.resp(conn, 200, body)
      end)

      check_json = %{
        "expects" => %{
          "expectation" => "active_trip_min_length",
          "routes" => ["jc-fail-route"],
          "multiplier" => 0.5
        }
      }

      assert {:ok, json_check} = JsonCheck.from_json(check_json)
      # 10 trips * 0.5 = 5 minimum; providing only 4 items
      params = %Params{decoded_body: Enum.map(1..4, &%{"id" => &1})}
      assert {:error, :array_too_small, length: 4} = JsonCheck.run_check(json_check, params)
    end

    test "returns error when trip count fetch fails", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/trips", fn conn ->
        Plug.Conn.resp(conn, 503, "unavailable")
      end)

      check_json = %{
        "expects" => %{
          "expectation" => "active_trip_min_length",
          "routes" => ["jc-error-route"],
          "multiplier" => 0.5
        }
      }

      assert {:ok, json_check} = JsonCheck.from_json(check_json)
      params = %Params{decoded_body: [1, 2, 3]}
      assert {:error, :trip_count_unavailable, reason: _} = JsonCheck.run_check(json_check, params)
    end

    test "get_expectation_func/1 returns error for missing routes" do
      assert {:error, :no_such_expectation} =
               JsonCheck.get_expectation_func(%{
                 "expectation" => "active_trip_min_length",
                 "routes" => [],
                 "multiplier" => 0.5
               })
    end

    test "get_expectation_func/1 returns error for non-positive multiplier" do
      assert {:error, :no_such_expectation} =
               JsonCheck.get_expectation_func(%{
                 "expectation" => "active_trip_min_length",
                 "routes" => ["Red"],
                 "multiplier" => 0
               })
    end
  end
end
