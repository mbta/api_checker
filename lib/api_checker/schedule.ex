defmodule ApiChecker.Schedule do
  @moduledoc """
  Keeps track of the scheduled tasks.
  """

  def get_filename() do
    Application.get_env(:api_checker, :checks_config_json_filename)
  end

  use GenServer
  alias ApiChecker.PeriodicTask
  # @json_checks_config_file_path "./priv/checks_config.json"

  defstruct tasks: []

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_tasks() do
    GenServer.call(__MODULE__, :get_tasks)
  end

  def init(_) do
    periodic_tasks = load_config_file()
    {:ok, %__MODULE__{tasks: periodic_tasks}}
  end

  def handle_call(:get_tasks, _from, state) do
    {:reply, state.tasks, state}
  end

  def load_config_file() do
    filename = get_filename()

    if !is_binary(filename) do
      raise "A filename is required to configure ApiChecker via json"
    end

    filepath = Path.join(["./priv", filename])

    filepath
    |> File.read!()
    |> Jason.decode!()
    |> to_periodic_tasks!(filepath)
  end

  def to_periodic_tasks!(checks, filepath) do
    Enum.map(checks, fn check -> periodic_task_from_json_config!(check, filepath) end)
  end

  def periodic_task_from_json_config!(json_check_config, filepath) do
    case PeriodicTask.from_json(json_check_config) do
      {:ok, periodic_task} ->
        periodic_task

      {:error, _} = err ->
        raise "Error in #{inspect(filepath)}': #{inspect(err)}"
    end
  end
end
