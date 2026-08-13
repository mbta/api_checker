import Config

case Mix.env() do
  :dev ->
    config :api_checker, check_filename: "priv/dev_checks_config.json"

  :test ->
    config :logger, default_handler: false
    config :api_checker, check_filename: "priv/test_checks_config.json"

  _ ->
    :ok
end
