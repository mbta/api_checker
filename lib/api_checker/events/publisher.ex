defmodule ApiChecker.Events.Publisher do
  @moduledoc """
  Publishes `com.mbta.api-checker.check` CloudEvents (see
  `ApiChecker.Events.CheckEvent`) to an AWS Kinesis stream whenever a
  check runs.

  The Kinesis stream name is read from the `KINESIS_STREAM_NAME`
  environment variable (see `ApiChecker.Application`). The AWS client
  used to actually send the record is configurable via the
  `:api_checker, :kinesis_client` application config, defaulting to
  `ApiChecker.Events.KinesisClient.Noop` in the `dev` and `test` Mix
  environments so that running the app (or its tests) locally never
  requires a real AWS connection.
  """
  require Logger
  alias ApiChecker.Events.CheckEvent

  @default_client ApiChecker.Events.KinesisClient.ExAws

  @doc """
  Publishes a check event for `check_name` with the given `success`
  boolean.

  If the `KINESIS_STREAM_NAME` environment variable isn't set (e.g.
  it hasn't been configured for the current deploy), this is a no-op
  and returns `:ok`.
  """
  @spec publish(String.t(), boolean) :: :ok | {:error, term}
  def publish(check_name, success) when is_binary(check_name) and is_boolean(success) do
    case stream_name() do
      stream_name when is_binary(stream_name) and stream_name != "" ->
        event = CheckEvent.build(check_name, success)
        data = CheckEvent.encode(event)
        client().put_record(stream_name, check_name, data)

      _ ->
        Logger.debug(fn ->
          "Kinesis Publish Skipped - reason=:no_stream_name_configured check_name=#{inspect(check_name)}"
        end)

        :ok
    end
  end

  @doc """
  Given the result of running a check (as returned by
  `ApiChecker.Check.run_check/2`), returns whether the check succeeded.

  iex> ApiChecker.Events.Publisher.success?(:ok)
  true

  iex> ApiChecker.Events.Publisher.success?({:ok, length: 1})
  true

  iex> ApiChecker.Events.Publisher.success?({:error, :stale_data})
  false

  iex> ApiChecker.Events.Publisher.success?({:error, :array_too_small, length: 0})
  false
  """
  @spec success?(term) :: boolean
  def success?(:ok), do: true
  def success?({:ok, _additional_data}), do: true
  def success?({:error, _reason}), do: false
  def success?({:error, _reason, _additional_data}), do: false

  defp stream_name do
    Application.get_env(:api_checker, :kinesis_stream_name)
  end

  defp client do
    Application.get_env(:api_checker, :kinesis_client, @default_client)
  end
end
