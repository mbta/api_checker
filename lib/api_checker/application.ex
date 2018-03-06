defmodule ApiChecker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @doc """
  Automatically sets up config env var 
  """
  def load_env_vars_from_file do
    config = System.get_env(ApiChecker.Schedule.env_var())

    filename =
      case {Mix.env(), config} do
        {:test, nil} -> "./priv/test_checks_config.json"
        {:dev, nil} -> "./priv/dev_checks_config.json"
        _ -> nil
      end

    case filename do
      x when is_binary(x) ->
        config = File.read!(filename)
        System.put_env(ApiChecker.Schedule.env_var(), config)

      _ ->
        :ok
    end
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
