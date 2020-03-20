defmodule ElixirDemo.Monitor.Workers do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def spawn_workers(worker_num) do
    IO.puts "spawning #{worker_num} workers"

    GenServer.call(__MODULE__, {:spawn, worker_num}, 60_000)
  end

  def shutdown_workers() do
    GenServer.call(__MODULE__, :shutdown_workers)
  end

  def process_job() do
    ts = timestamp()

    if :ets.lookup(__MODULE__, {:jobs_processed, ts}) == [] do
      :ets.insert(__MODULE__, {{:jobs_processed, ts}, 0})
    end

    :ets.update_counter(__MODULE__, {:jobs_processed, ts}, 1)
  end
  def workers_limit(), do: GenServer.call(__MODULE__, :workers_limit)
  def join_worker(), do: :ets.update_counter(__MODULE__, :workers, 1)
  def leave_worker(), do: :ets.update_counter(__MODULE__, :workers, -1)

  def workers() do
    [{_, count}] = :ets.lookup(__MODULE__, :workers)
    count
  end

  def jobs_rate(), do: GenServer.call(__MODULE__, :jobs_rate)

  # Server callbacks
  def init(:ok) do
    IO.puts "starting workers"

    :ets.new(__MODULE__, [:named_table, :public, write_concurrency: true, read_concurrency: false])
    :ets.insert(__MODULE__, {:jobs_processed, 0})
    :ets.insert(__MODULE__, {:workers, 0})

    {:ok, %{time: 0, workers_limit: 0}}
  end

  def handle_call(:shutdown_workers, _from, _state), do: {:reply, :ok, %{time: 0, workers_limit: 0}}

  def handle_call(:workers_limit, _from, %{workers_limit: limit} = state), do: {:reply, limit, state}

  def handle_call(:jobs_rate, _from, state) do
    rate = case :ets.lookup(__MODULE__, {:jobs_processed, timestamp() -1}) do
      [{_, count}] -> count
      _ -> 0
    end

    {:reply, rate, state}
  end

  def handle_call(:count_workers, _from, %{pids: pids} = state) do
    {:reply, Enum.count(pids), state}
  end

  def handle_call({:spawn, number_of_workers}, _from, %{workers_limit: limit}) do
    # Settings new timer & reset jobs processed
    time = :erlang.monotonic_time()
    :ets.insert(__MODULE__, {:jobs_processed, 0})

    if number_of_workers > limit do
      1..(number_of_workers - limit) |> Enum.each(fn id ->
        ElixirDemo.Monitor.Worker.spawn(id)
      end)
    end

    # Sending new state
    {:reply, :ok, %{time: time, workers_limit: number_of_workers}}
  end

  #
  # Private
  #
  defp timestamp(), do: :calendar.universal_time() |> :calendar.datetime_to_gregorian_seconds()
end
