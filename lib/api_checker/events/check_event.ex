defmodule ApiChecker.Events.CheckEvent do
  @moduledoc """
  Builds CloudEvents-formatted events for the
  `com.mbta.api-checker.check` schema, documented at
  https://mbta.github.io/schemas/events/com.mbta.api-checker.check

  These events describe an instance of an API Checker check running
  and its result.
  """

  @source "api-checker"
  @specversion "1.0"
  @type_name "com.mbta.api-checker.check.v1"

  @type t :: %{
          data: %{checkName: String.t(), success: boolean},
          id: String.t(),
          source: String.t(),
          specversion: String.t(),
          time: String.t(),
          type: String.t()
        }

  @doc """
  Builds a CloudEvent map for a check's name and result, ready to be
  JSON-encoded and published.

  iex> event = ApiChecker.Events.CheckEvent.build("heavy-rail-predictions-weekdays", true)
  iex> event.data
  %{checkName: "heavy-rail-predictions-weekdays", success: true}
  iex> event.source
  "api-checker"
  iex> event.specversion
  "1.0"
  iex> event.type
  "com.mbta.api-checker.check.v1"
  """
  @spec build(String.t(), boolean, DateTime.t()) :: t
  def build(check_name, success, now \\ DateTime.utc_now())

  def build(check_name, success, %DateTime{} = now) when is_binary(check_name) and is_boolean(success) do
    %{
      data: %{
        checkName: check_name,
        success: success
      },
      id: event_id(),
      source: @source,
      specversion: @specversion,
      time: DateTime.to_iso8601(now),
      type: @type_name
    }
  end

  @doc """
  JSON-encodes a built event.
  """
  @spec encode(t) :: String.t()
  def encode(event) do
    Jason.encode!(event)
  end

  # Generates a random (version 4) UUID to use as the CloudEvent's `id`.
  # A dependency-free implementation, since only randomness (not
  # time-ordering or any other property) is required here.
  defp event_id do
    <<u0::32, u1::16, _::4, u2::12, _::2, u3::62>> = :crypto.strong_rand_bytes(16)

    Base.encode16(<<u0::32, u1::16, 4::4, u2::12, 2::2, u3::62>>, case: :lower)
    |> insert_dashes()
  end

  defp insert_dashes(<<a::binary-size(8), b::binary-size(4), c::binary-size(4), d::binary-size(4), e::binary-size(12)>>) do
    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end
end
