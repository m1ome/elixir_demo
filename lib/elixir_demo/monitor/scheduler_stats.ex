defmodule ElixirDemo.Monitor.SchedulerStats do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def utilization() do
    [{_, usage}] = :ets.lookup(__MODULE__, :scheduler_usage)
    usage
  end

  def init(opts) do
    :ets.new(__MODULE__, [:named_table, :public, write_concurrency: true, read_concurrency: false])
    :ets.insert(__MODULE__, {:scheduler_usage, 0})
    enqueue_next()

    {:ok, opts}
  end

  def handle_info(:emit_stats, _state) do
    Task.start_link(fn ->
      # Measure a one second utilization
      utilization = :scheduler.utilization(1)
      |> Enum.filter(fn item ->
        case item do
          {:normal, _, _, _} -> true
          _ -> false
        end
      end)
      |> Enum.take(:erlang.system_info(:schedulers_online))
      |> Enum.reduce(0, fn {:normal, _, usage, _}, acc ->
        acc + usage
      end)


      :ets.insert(__MODULE__, {:scheduler_usage, utilization})
      enqueue_next()
    end)

    {:noreply, 0}
  end

  defp enqueue_next(), do: Process.send_after(__MODULE__, :emit_stats, 100)
end
