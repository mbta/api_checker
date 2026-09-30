import Config

# ex_aws uses Jason (already a dependency) instead of the default Poison
config :ex_aws, json_codec: Jason

case Mix.env() do
  :dev ->
    config :api_checker, check_filename: "priv/dev_checks_config.json"
    # Avoid connecting to a real Kinesis stream when running locally.
    config :api_checker, kinesis_client: ApiChecker.Events.KinesisClient.Noop

  :test ->
    config :logger, default_handler: false
    config :api_checker, check_filename: "priv/test_checks_config.json"
    # Avoid connecting to a real Kinesis stream in the test suite.
    config :api_checker, kinesis_client: ApiChecker.Events.KinesisClient.Noop

  _ ->
    config :api_checker, kinesis_client: ApiChecker.Events.KinesisClient.ExAws
end
