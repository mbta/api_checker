defmodule ApiChecker.JsonCheck.ArrayTest do
  use ExUnit.Case, async: true
  alias ApiChecker.JsonCheck.{Array, Jsonapi}
  doctest ApiChecker.JsonCheck.Array

  describe "validate_items/2" do
    test "works for a list of valid items" do
      valid_items = [
        %{"version" => "1.0"},
        %{"version" => "1.0"},
        %{"version" => "1.0"}
      ]

      assert :ok = Array.validate_items(valid_items, &Jsonapi.validate/1)
    end

    test "errors for any invalid items" do
      invalid_items = [
        # BECAUSE THIS IS INVALID VERSION
        %{"version" => "1.1"}
      ]

      assert {:error, _} = Array.validate_items(invalid_items, &Jsonapi.validate/1)
    end
  end
end
