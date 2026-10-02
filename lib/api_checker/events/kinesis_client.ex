defmodule ApiChecker.Events.KinesisClient do
  @moduledoc """
  Behaviour for putting a single CloudEvent record onto an AWS Kinesis
  stream. Having this as a behaviour lets the real AWS-backed
  implementation be swapped out (e.g. for local development or tests)
  via the `:api_checker, :kinesis_client` application config.
  """

  @callback put_record(stream_name :: String.t(), partition_key :: String.t(), data :: binary) ::
              :ok | {:error, term}
end

defmodule ApiChecker.Events.KinesisClient.ExAws do
  @moduledoc """
  Real `ApiChecker.Events.KinesisClient` implementation, backed by the
  `ex_aws` and `ex_aws_kinesis` libraries. Used to actually publish
  CloudEvents to AWS Kinesis, e.g. in production.
  """
  @behaviour ApiChecker.Events.KinesisClient
  require Logger

  @impl true
  def put_record(stream_name, partition_key, data) do
    case stream_name
         |> ExAws.Kinesis.put_record(partition_key, data)
         |> ExAws.request() do
      {:ok, _result} ->
        :ok

      {:error, reason} = err ->
        Logger.error("Kinesis Error - reason=#{inspect(reason)} stream_name=#{inspect(stream_name)}")

        err
    end
  end
end

defmodule ApiChecker.Events.KinesisClient.Noop do
  @moduledoc """
  A `ApiChecker.Events.KinesisClient` implementation that doesn't
  actually connect to AWS Kinesis. Used by default in the `dev` and
  `test` Mix environments so that the app (and its test suite) can run
  locally without AWS credentials or a real Kinesis stream.

  Instead of sending the record, it logs the fact that it would have
  been sent.
  """
  @behaviour ApiChecker.Events.KinesisClient
  require Logger

  @impl true
  def put_record(stream_name, partition_key, data) do
    Logger.debug(
      "Kinesis Noop - stream_name=#{inspect(stream_name)} partition_key=#{inspect(partition_key)} data=#{inspect(data)}"
    )

    :ok
  end
end
