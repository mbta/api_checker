defmodule ApiChecker.CheckTest do
  use ExUnit.Case, async: true
  alias ApiChecker.Check
  alias ApiChecker.Check.{JsonCheck, Params}

  describe "from_json/1" do
    test "valid json is turned into a struct as expected and is run_check-able" do
      valid_json_check = %{
        "type" => "json",
        "keypath" => "jsonapi",
        "expects" => "jsonapi"
      }

      assert {:ok, %JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"}} = Check.from_json(valid_json_check)
    end

    test "unsupported json type returns error" do
      unsupported_check = %{
        "type" => "not_supported"
      }

      assert Check.from_json(unsupported_check) == {:error, :unsupported_check_type}
    end
  end

  describe "run_check/2" do
    test "can handle valid JsonCheck struct and valid body" do
      json_check = %JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"}

      decoded_body = %{
        "jsonapi" => %{
          "version" => "1.0"
        }
      }

      params = %Params{decoded_body: decoded_body}

      assert :ok = Check.run_check(json_check, params)
    end

    test "can handle valid JsonCheck struct with invalid body" do
      json_check = %JsonCheck{keypath: ["jsonapi"], expects: "jsonapi"}

      decoded_body = %{
        "jsonapi" => %{
          "unexpected" => "1.0"
        }
      }

      params = %Params{decoded_body: decoded_body}

      assert {:error, _} = Check.run_check(json_check, params)
    end
  end
end
