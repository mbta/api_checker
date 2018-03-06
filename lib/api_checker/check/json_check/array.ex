defmodule ApiChecker.Check.JsonCheck.Array do
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

end
