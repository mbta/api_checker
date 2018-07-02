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
      iex> payload = %{"data" => ["oh_look_some_vehicles"]}
      iex> params = %Params{decoded_body: payload}
      iex> {:ok, json_check} = JsonCheck.from_json(json_check_config)
      iex> JsonCheck.run_check(json_check, params)
      {:ok, length: 1}
  """

  alias ApiChecker.Check.{JsonCheck, Params}
  alias JsonCheck.{Jsonapi, Array}

  defstruct keypath: [],
            # params: nil, # keep this here for the future -JLG
            expects: nil

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
  def expectation_exists?(name) do
    case get_expectation_func(name) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Get an expectation by name given a string.

  Returns {:ok, function} or {:error, :no_such_expectation}

  iex> JsonCheck.get_expectation_func("jsonapi")
  {:ok, &Jsonapi.validate/1}

  iex> JsonCheck.get_expectation_func("not_empty")
  {:ok, &Array.validate_not_empty/1}

  iex> JsonCheck.get_expectation_func("jsonapi") |> elem(1) |> is_function(1)
  true

  iex> JsonCheck.get_expectation_func("unknown")
  {:error, :no_such_expectation}
  """
  def get_expectation_func("jsonapi"), do: {:ok, &Jsonapi.validate/1}
  def get_expectation_func("not_empty"), do: {:ok, &Array.validate_not_empty/1}

  def get_expectation_func(%{"expectation" => "min_length", "min_length" => min_length})
      when is_integer(min_length) and min_length > 0,
      do: {:ok, &Array.validate_min_length(&1, min_length)}

  def get_expectation_func(_), do: {:error, :no_such_expectation}

  @doc """
  Turns valid json into a ready-to-use JsonCheck struct.
  """
  def from_json(json) when is_map(json) do
    with {:ok, expectation_name} <- Map.fetch(json, "expects") do
      {:ok,
       %JsonCheck{
         keypath: json |> Map.get("keypath") |> List.wrap(),
         expects: expectation_name
       }}
    else
      {:error, _} = err ->
        err

      _ ->
        {:error, :invalid_json_check_config}
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
