defmodule ApiCheckerTest do
  use ExUnit.Case
  doctest ApiChecker

  test "greets the world" do
    assert ApiChecker.hello() == :world
  end
end
