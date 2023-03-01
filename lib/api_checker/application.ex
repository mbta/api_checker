defmodule ApiChecker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias ApiChecker.Schedule

  use Application

  @doc """
  Automatically sets up config env var
  """
  def load_env_vars_from_file do
    with nil <- System.get_env(Schedule.env_var()),
         check_filename when is_binary(check_filename) <- Application.get_env(:api_checker, :check_filename) do
      config = File.read!(check_filename)
      System.put_env(Schedule.env_var(), config)
    end
  end

  def start(_type, _args) do
    # Invoke Sentry logger:
    _ = Logger.add_backend(Sentry.LoggerBackend)
    load_env_vars_from_file()
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: ApiChecker.Worker.start_link(arg)
      # {ApiChecker.Worker, arg},
      # {ApiChecker.Schedule, nil},
      {ApiChecker.Holiday, name: ApiChecker.Holiday},
      {ApiChecker.PreviousResponse, nil},
      {ApiChecker.Scheduler, nil}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ApiChecker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
