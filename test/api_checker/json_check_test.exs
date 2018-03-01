defmodule ApiChecker.JsonCheckTest do
  use ExUnit.Case, async: true
  alias ApiChecker.JsonCheck
  alias ApiChecker.JsonCheck.{Vehicle, Jsonapi, Array}
  doctest ApiChecker.JsonCheck

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

      assert :ok = JsonCheck.run_check(json_check, valid_json)
      assert {:error, _} = JsonCheck.run_check(json_check, invalid_json1)
      assert {:error, _} = JsonCheck.run_check(json_check, invalid_json2)
    end
  end
end
