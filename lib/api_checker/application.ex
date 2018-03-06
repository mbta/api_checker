defmodule ApiChecker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def load_env_vars_from_file do
    filename = case Mix.env() do
      :test -> "./priv/test_checks_config.json"
      :dev  -> "./priv/dev_checks_config.json"
      :prod  -> "./priv/prod_checks_config.json"
    end
    System.put_env("API_CHECKER_CONFIGURATION", File.read!(filename))
  end

  def start(_type, _args) do
    load_env_vars_from_file()
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: ApiChecker.Worker.start_link(arg)
      # {ApiChecker.Worker, arg},
      # {ApiChecker.Schedule, nil},
      {ApiChecker.PreviousResponse, nil},
      {ApiChecker.Scheduler, nil}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ApiChecker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
