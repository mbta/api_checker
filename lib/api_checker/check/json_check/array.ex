defmodule ApiChecker.Check.JsonCheck.Array do
  @moduledoc """
  Functions for validating JSON arrays.
  """

  @doc """
  Returns :ok for lists that are not empty.
  Returns {:error, :array_was_empty} for an empty list (array).
  Returns {:error, :invalid_array} for a non-list.

  iex> Array.validate_not_empty(["ok"])
  {:ok, length: 1}

  iex> Array.validate_not_empty([])
  {:error, :array_was_empty}

  iex> Array.validate_not_empty(:ok)
  {:error, :invalid_array}
  """
  def validate_not_empty([]) do
    {:error, :array_was_empty}
  end

  def validate_not_empty([_ | _] = list) do
    {:ok, length: length(list)}
  end

  def validate_not_empty(_) do
    {:error, :invalid_array}
  end

  @doc """
  Returns {:ok, length: length} for lists that are at least the provided length
  Returns {:error, {:array_too_small, length}} if the array is too small.
  Returns {:error, :invalid_array} if the argument is not a list.

  iex> Array.validate_min_length([1, 2], 2)
  {:ok, length: 2}

  iex> Array.validate_min_length([1], 2)
  {:error, {:array_too_small, 1}}

  iex> Array.validate_min_length(:ok, 1)
  {:error, :invalid_array}
  """
  def validate_min_length(list, min_length) when is_list(list) do
    list_length = length(list)

    if list_length >= min_length do
      {:ok, length: list_length}
    else
      {:error, {:array_too_small, list_length}}
    end
  end

  def validate_min_length(_, _) do
    {:error, :invalid_array}
  end
end
