defmodule ApiChecker.Check do
  @moduledoc """
  Context for running configurable "checks".
  """
  alias ApiChecker.JsonCheck

  def from_json(%{"type" => "json"} = json) do
    JsonCheck.from_json(json)
  end

  def from_json(_) do
    {:error, :unsupported_check_type}
  end

  @supported_checks [JsonCheck]

  def run_check(%module{} = check, params) when module in @supported_checks do
    module.run_check(check, params)
  end
end
