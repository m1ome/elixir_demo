defmodule ElixirDemo.Monitor.Worker do
  def spawn(id) do
    Task.start_link(fn ->
      ElixirDemo.Monitor.Workers.join_worker()
      :timer.sleep(1000)
      loop(id)
    end)
  end

  def loop(id) do
    if id <= ElixirDemo.Monitor.Workers.workers_limit() do
      _ =  1..50 |> Enum.reduce(0, &(&1+&2))
      ElixirDemo.Monitor.Workers.process_job()
      :erlang.garbage_collect()
      :timer.sleep(1000)
      loop(id)
    end
  end
end
