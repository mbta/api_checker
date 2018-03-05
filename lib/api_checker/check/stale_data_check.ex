defmodule ApiChecker.Check.StaleDataCheck do
  @moduledoc """
  Run stale data checks against previous requests.
  """

  alias ApiChecker.PreviousResponse
  alias ApiChecker.Check.Params

  defstruct time_limit_in_seconds: nil

  @doc """
  Turns a valid stale data json configuration into an ok-struct or error tuple.
  """
  def from_json(%{"time_limit_in_seconds" => limit}) when is_integer(limit) and limit > 0 do
    {:ok, %__MODULE__{time_limit_in_seconds: limit}}
  end

  def from_json(_) do
    {:error, :invalid_stale_data_check_config}
  end

  @doc """
  Runs a stale data check against the previous batch's state.
  """
  def run_check(_, %Params{previous_response: nil}) do
    # since the previous_response is nil this check must be new
    # therefore no stale data exists.
    :ok
  end

  def run_check(%__MODULE__{} = check, %Params{previous_response: prev} = params) do
    if is_old_enough_to_be_stale?(check, prev, params.check_time) do
      case prev.body == params.raw_body do
        true ->
          {:error, :stale_data}

        _ ->
          :ok
      end
    else
      :ok
    end
  end

  @doc """
  Diffs a time in the past with a given time (default: now) and compares the diff
  to a limit.
  """
  def is_old_enough_to_be_stale?(limit, updated_at, check_time \\ DateTime.utc_now())

  def is_old_enough_to_be_stale?(%__MODULE__{time_limit_in_seconds: limit}, previous_response, check_time) do
    is_old_enough_to_be_stale?(limit, previous_response, check_time)
  end

  def is_old_enough_to_be_stale?(limit, %PreviousResponse{updated_at: updated_at}, check_time) do
    is_old_enough_to_be_stale?(limit, updated_at, check_time)
  end

  def is_old_enough_to_be_stale?(limit, %DateTime{} = updated_at, %DateTime{} = check_time) when is_integer(limit) do
    DateTime.diff(check_time, updated_at) >= limit
  end

  def validate_struct(%__MODULE__{time_limit_in_seconds: limit}) when is_integer(limit) and limit > 0 do
    :ok
  end

  def validate_struct(_) do
    {:error, :invalid_stale_data_check_config}
  end
end
