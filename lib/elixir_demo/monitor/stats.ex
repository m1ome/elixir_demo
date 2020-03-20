defmodule ElixirDemo.Monitor.Stats do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stats(), do: GenServer.call(__MODULE__, :stats)

  #
  # Callbacks
  #
  def init(_) do
    IO.puts "starting stats"

    enqueue_next()
    {:ok, %{points: []}}
  end

  def handle_call(:stats, _from, state), do: {:reply, state.points, state}

  def handle_info(:emit_stats, state) do
    enqueue_next()

    new_point = %{
      jobs_rate: ElixirDemo.Monitor.Workers.jobs_rate(),
      schedulers_usage: ElixirDemo.Monitor.SchedulerStats.utilization(),
      memory_usage: div(:erlang.memory(:total), 1024 * 1024),
      workers_count: ElixirDemo.Monitor.Workers.workers(),
      scheduler_count: :erlang.system_info(:schedulers_online)
    }

    previous_points = Enum.take(state.points, 99)

    {:noreply,
     %{state | points: [new_point | previous_points]}
    }
  end

  #
  # Private
  #
  defp enqueue_next(), do: Process.send_after(self(), :emit_stats, 100)
end
