defmodule ApiChecker.ApiValidator do
  @moduledoc """
  Takes json configuration and parses it into a valid ApiValidator
  struct which can be used to validate json payloads.

  # Example

  Given a valid `validator_config` and a valid `json_payload`,
  an `ApiValidator` struct can be generated and used to validate
  the `json_payload`. Using the `["array", "not_empty"]` as the `validator`
  and `"data"` as the `keypath` in the `validator_config` the
  `json_payload`'s `data` field is checked for a non-empty-array value (cannot be `[]`):

      iex> validator_config = %{"keypath" => "data", "validator" => ["array", "not_empty"]}
      %{"keypath" => "data", "validator" => ["array", "not_empty"]}
      iex> payload = %{"data" => ["oh_look_some_vehicles"]}
      %{"data" => ["oh_look_some_vehicles"]}
      iex> {:ok, api_validator} = ApiValidator.from_json(validator_config)
      {:ok, %ApiValidator{keypath: ["data"], validator: ["array", "not_empty"]}}
      iex> ApiValidator.run_validator(api_validator, payload)
      :ok
  """

  alias ApiChecker.ApiValidator
  alias ApiChecker.ApiValidator.{Vehicle, Jsonapi, Array}

  defstruct keypath: nil,
            # params: nil, # keep this here for the future -JLG
            validator: nil

  @validators %{
    "vehicle" => &Vehicle.validate/1,
    "jsonapi" => &Jsonapi.validate/1,
    "not_empty" => &Array.validate_not_empty/1,
    ["array", "not_empty"] => &Array.validate_not_empty/1
  }

  @doc """
  Get a validator by name given a string or a list/array validator by name
  by providing `["array", <validator_name_here>]`.

  Returns {:ok, function} or {:erorr, :validator_not_found}

  iex> ApiValidator.get_validator_func("vehicle")
  {:ok, &Vehicle.validate/1}

  iex> ApiValidator.get_validator_func("jsonapi")
  {:ok, &Jsonapi.validate/1}

  iex> ApiValidator.get_validator_func(["array", "not_empty"])
  {:ok, &Array.validate_not_empty/1}

  iex> ApiValidator.get_validator_func(["array", "jsonapi"]) |> elem(1) |> is_function(1)
  true
  """
  def get_validator_func(name) when is_binary(name) do
    case Map.fetch(@validators, name) do
      {:ok, _} = ok_func ->
        ok_func

      _ ->
        {:error, :no_such_validator}
    end
  end

  def get_validator_func(["array", "not_empty"]) do
    {:ok, &Array.validate_not_empty/1}
  end

  def get_validator_func(["array", subname]) when is_binary(subname) do
    case get_validator_func(subname) do
      {:ok, validator} ->
        validator_func = fn items ->
          Array.validate_items(items, validator)
        end

        {:ok, validator_func}

      error ->
        error
    end
  end

  def validate_func_name(name) when is_binary(name) when is_list(name) do
    case get_validator_func(name) do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  end

  @doc """
  Turns valid json into a ready-to-use ApiValidator struct.
  """
  def from_json(json) when is_map(json) do
    with {:ok, validator_name} <- Map.fetch(json, "validator") do
      {:ok,
       %ApiValidator{
         keypath: json |> Map.get("keypath") |> parse_keypath,
         validator: validator_name
       }}
    else
      {:error, _} = err ->
        err

      _ ->
        {:error, :invalid_validator_config}
    end
  end

  defp parse_keypath(raw_keypath) do
    case raw_keypath do
      nil -> []
      x when is_binary(x) -> [x]
      x when is_list(x) -> x
    end
  end

  def run_validator(%ApiValidator{} = api_validator, data) do
    found = get_keypath(api_validator, data)

    case get_validator_func(api_validator.validator) do
      {:ok, validator_func} ->
        validator_func.(found)

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Given an map or list and a list of keys gets a nested keypath from
  map or items in list.

  iex> ApiValidator.get_keypath(%ApiValidator{keypath: []}, %{"foo" => "data"})
  %{"foo" => "data"}

  iex> ApiValidator.get_keypath(%ApiValidator{keypath: ["foo"]}, %{"foo" => "data"})
  "data"

  iex> ApiValidator.get_keypath(%ApiValidator{keypath: ["foo"]}, %{"foo" => "data"})
  "data"

  iex> ApiValidator.get_keypath(%ApiValidator{keypath: ["foo"]}, [%{"foo" => "data"}, %{"foo" => "bar"}])
  ["data", "bar"]
  """
  def get_keypath(%ApiValidator{keypath: []}, data) do
    data
  end

  def get_keypath(%ApiValidator{keypath: keypath}, data) do
    get_keypath(keypath, data)
  end

  def get_keypath(keypath, data) when is_list(data) and is_list(keypath) do
    Enum.map(data, fn item -> get_keypath(keypath, item) end)
  end

  def get_keypath(keypath, data) when is_map(data) and is_list(keypath) do
    get_in(data, keypath)
  end
end
