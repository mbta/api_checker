defmodule ApiCheckerTest do
  use ExUnit.Case, async: true
  doctest ApiChecker

  describe "tasks_due/0" do
    test "with tasks due for given datetime"
    test "without tasks due for given datetime"
  end
end
