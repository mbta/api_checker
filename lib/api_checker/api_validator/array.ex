defmodule ApiChecker.ApiValidator.Array do
  @moduledoc """
  Functions for validating JSON arrays.
  """

  @doc """
  Returns :ok for lists that are not empty.
  Returns {:error, :array_was_empty} for an empty list (array).
  Returns {:error, :invalid_array} for a non-list.

  iex> Array.validate_not_empty(["ok"])
  :ok

  iex> Array.validate_not_empty([])
  {:error, :array_was_empty}

  iex> Array.validate_not_empty(:ok)
  {:error, :invalid_array}
  """
  def validate_not_empty([]) do
    {:error, :array_was_empty}
  end

  def validate_not_empty(list) when is_list(list) do
    :ok
  end

  def validate_not_empty(_) do
    {:error, :invalid_array}
  end

  @doc """
  Reduces a json array (list) with a validator.
  Returns :ok or {:error, reason}.

  See `test/api_validator/array_test.exs` for examples.
  """
  def validate_items(items, validator_func) when is_function(validator_func, 1) and is_list(items) do
    # to extend description include index for error results
    Enum.reduce(items, :ok, fn
      item, :ok -> validator_func.(item)
      _, acc -> acc
    end)
  end

  def validate_items(_not_an_array, validator_func) when is_function(validator_func, 1) do
    {:error, :invalid_array}
  end
end
