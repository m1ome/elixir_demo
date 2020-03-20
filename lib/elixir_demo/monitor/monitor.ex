defmodule ElixirDemo.Monitor do
  def change_schedulers(schedulers) do
    :erlang.system_flag(:schedulers_online, schedulers)
    :erlang.system_flag(:dirty_cpu_schedulers_online, schedulers)
  end

  def change_jobs(jobs), do: ElixirDemo.Monitor.Workers.spawn_workers(jobs)

  def stats(), do: ElixirDemo.Monitor.Stats.stats()
end
