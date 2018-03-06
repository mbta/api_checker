defmodule ApiChecker.Check.JsonCheck do
  @moduledoc """
  Takes json configuration and parses it into a valid JsonCheck
  struct which can be used to validate json payloads.

  # Example

  Given a valid `json_check_config` and a valid `json_payload`,
  an `JsonCheck` struct can be generated and used to validate
  the `json_payload`. Using `"not_empty"` as the `expects` field
  and `"data"` as the `keypath` field in the `json_check_config` the
  `json_payload`'s `data` field is checked for a non-empty-array value (cannot be `[]`):

      iex> json_check_config = %{"keypath" => "data", "expects" => "not_empty"}
      %{"keypath" => "data", "expects" => "not_empty"}
      iex> payload = %{"data" => ["oh_look_some_vehicles"]}
      %{"data" => ["oh_look_some_vehicles"]}
      iex> params = %Params{decoded_body: payload}
      %Params{decoded_body: %{"data" => ["oh_look_some_vehicles"]}}
      iex> {:ok, json_check} = JsonCheck.from_json(json_check_config)
      {:ok, %JsonCheck{keypath: ["data"], expects: "not_empty"}}
      iex> JsonCheck.run_check(json_check, params)
      :ok
  """

  alias ApiChecker.Check.{JsonCheck, Params}
  alias JsonCheck.{Vehicle, Jsonapi, Array}

  defstruct keypath: [],
            # params: nil, # keep this here for the future -JLG
            expects: nil

  @expectations %{
    "vehicle" => &Vehicle.validate/1,
    "jsonapi" => &Jsonapi.validate/1,
    "not_empty" => &Array.validate_not_empty/1
  }

  @doc """
  Validates the fields of an JsonCheck struct
  """
  def validate_struct(%JsonCheck{keypath: keypath, expects: expects}) do
    with true <- is_list(keypath),
         true <- expectation_exists?(expects) do
      :ok
    else
      {:error, _} = err ->
        err

      _ ->
        {:error, :invalid_json_check_config}
    end
  end

  @doc """
  Returns true if a expectation of that name exists, else false.

  iex> JsonCheck.expectation_exists?("not_empty")
  true
  """
  def expectation_exists?(name) when is_list(name) when is_binary(name) do
    case get_expectation_func(name) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Get an expectation by name given a string or a list/array expectation by name
  by providing `["array", <expectation_name_here>]`.

  Returns {:ok, function} or {:error, :expecation_not_found}

  iex> JsonCheck.get_expectation_func("vehicle")
  {:ok, &Vehicle.validate/1}

  iex> JsonCheck.get_expectation_func("jsonapi")
  {:ok, &Jsonapi.validate/1}

  iex> JsonCheck.get_expectation_func("not_empty")
  {:ok, &Array.validate_not_empty/1}

  iex> JsonCheck.get_expectation_func("jsonapi") |> elem(1) |> is_function(1)
  true
  """
  def get_expectation_func(name) when is_binary(name) do
    case Map.fetch(@expectations, name) do
      {:ok, _} = ok_func ->
        ok_func

      _ ->
        {:error, :no_such_expectation}
    end
  end

  def validate_func_name(name) when is_binary(name) when is_list(name) do
    case get_expectation_func(name) do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  end

  @doc """
  Turns valid json into a ready-to-use JsonCheck struct.
  """
  def from_json(json) when is_map(json) do
    with {:ok, expectation_name} <- Map.fetch(json, "expects") do
      {:ok,
       %JsonCheck{
         keypath: json |> Map.get("keypath") |> parse_keypath,
         expects: expectation_name
       }}
    else
      {:error, _} = err ->
        err

      _ ->
        {:error, :invalid_json_check_config}
    end
  end

  defp parse_keypath(raw_keypath) do
    case raw_keypath do
      nil -> []
      x when is_binary(x) -> [x]
      x when is_list(x) -> x
    end
  end

  def run_check(%JsonCheck{} = json_check, %Params{decoded_body: decoded_body}) do
    found = get_keypath(json_check, decoded_body)

    case get_expectation_func(json_check.expects) do
      {:ok, expectation_func} ->
        expectation_func.(found)

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Given an map or list and a list of keys gets a nested keypath from
  map or items in list.

  iex> JsonCheck.get_keypath(%JsonCheck{keypath: []}, %{"foo" => "data"})
  %{"foo" => "data"}

  iex> JsonCheck.get_keypath(%JsonCheck{keypath: ["foo"]}, %{"foo" => "data"})
  "data"

  iex> JsonCheck.get_keypath(%JsonCheck{keypath: ["foo"]}, %{"foo" => "data"})
  "data"

  iex> JsonCheck.get_keypath(%JsonCheck{keypath: ["foo"]}, [%{"foo" => "data"}, %{"foo" => "bar"}])
  ["data", "bar"]
  """
  def get_keypath(%JsonCheck{keypath: []}, data) do
    data
  end

  def get_keypath(%JsonCheck{keypath: keypath}, data) do
    get_keypath(keypath, data)
  end

  def get_keypath(keypath, data) when is_list(data) and is_list(keypath) do
    Enum.map(data, fn item -> get_keypath(keypath, item) end)
  end

  def get_keypath(keypath, data) when is_map(data) and is_list(keypath) do
    get_in(data, keypath)
  end
end
