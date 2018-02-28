defmodule ApiChecker.ApiValidatorTest do
  use ExUnit.Case
  alias ApiChecker.ApiValidator
  alias ApiChecker.ApiValidator.{Vehicle, Jsonapi, Array}
  doctest ApiChecker.ApiValidator

  describe "from_json/1" do
    test "valid json is turned into a struct as expected as is run_validator-able" do
      valid_json = %{
        "keypath" => "jsonapi",
        "validator" => "jsonapi"
      }

      assert {:ok, validator} = ApiValidator.from_json(valid_json)
      assert validator.keypath == ["jsonapi"]
      assert validator.validator == "jsonapi"

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

      assert :ok = ApiValidator.run_validator(validator, valid_json)
      assert {:error, _} = ApiValidator.run_validator(validator, invalid_json1)
      assert {:error, _} = ApiValidator.run_validator(validator, invalid_json2)
    end
  end
end
