defmodule ApiChecker.Check.JsonCheckTest do
  use ExUnit.Case, async: true
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
end
