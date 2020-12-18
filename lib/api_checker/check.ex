defmodule ApiChecker.Check do
  @moduledoc """
  Context for running configurable "checks".
  """
  alias ApiChecker.Check.{JsonCheck, StaleDataCheck}

  def from_json(%{"type" => "json"} = json) do
    JsonCheck.from_json(json)
  end

  def from_json(%{"type" => "stale"} = json) do
    StaleDataCheck.from_json(json)
  end

  def from_json(_) do
    {:error, :unsupported_check_type}
  end

  @supported_checks [JsonCheck, StaleDataCheck]

  def run_check(%module{} = check, params) when module in @supported_checks do
    module.run_check(check, params)
  end

  def validate(%module{} = check) when module in @supported_checks do
    module.validate_struct(check)
  end

  def validate(_) do
    {:error, :unsupported_check_struct}
  end
end
