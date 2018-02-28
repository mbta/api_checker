defmodule ApiChecker.ApiValidator.Jsonapi do
  @moduledoc """
  Validates the "jsonapi" field of an object.
  """

  @allowed_versions ["1.0"]

  @doc """
  Validates a jsonapi object.

  iex> Jsonapi.validate(%{"version" => "1.0"})
  :ok

  iex> Jsonapi.validate(%{"version" => "1.2"})
  {:error, :invalid_jsonapi_version}

  iex> Jsonapi.validate(%{})
  {:error, :invalid_jsonapi_object}
  """
  def validate(%{"version" => v}) when v in @allowed_versions do
    :ok
  end

  def validate(%{"version" => _}) do
    {:error, :invalid_jsonapi_version}
  end

  def validate(_) do
    {:error, :invalid_jsonapi_object}
  end
end
