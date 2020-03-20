defmodule ElixirDemoWeb.StatsLive do
  use Phoenix.LiveView

  @num_points 100

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(100, self(), :update)

    # Assigning them to socket
    socket = assign(socket, operations: [], number: changeset(0))
    {:ok, update_stats(socket)}
  end

  defp update_stats(socket) do
    stats = ElixirDemo.Monitor.stats()
    last_stat = stats |> List.last
    assign(socket,
      jobs: changeset(last_stat.workers_count),
      schedulers: changeset(last_stat.scheduler_count),
      jobs_graph: calc_jobs_graph(stats),
      scheduler_graph: calc_scheduler_graph(stats),
      memory: last_stat.memory_usage
    )
  end

  def render(assigns) do
    Phoenix.View.render(ElixirDemoWeb.PageView, "dashboard.html", assigns)
  end

  def handle_event("reset", _, socket) do
    ElixirDemo.Monitor.change_jobs(0)
    ElixirDemo.Monitor.change_schedulers(12)

    {:noreply, assign(socket,
      jobs: changeset(0),
      schedulers: changeset(12),
      operations: []
    )}
  end

  def handle_event("calculate", %{"data" => %{"value" => str_input}}, socket),
    do: {:noreply, start_sum(socket, str_input)}

  def handle_event("change_jobs", %{"data" => %{"value" => value}}, socket) do
    with {jobs, ""} <- Integer.parse(value) do
      ElixirDemo.Monitor.change_jobs(jobs)
      {:noreply, assign(socket, jobs: changeset(jobs))}
    end

    {:noreply, socket}
  end

  def handle_event("change_schedulers", %{"data" => %{"value" => value}}, socket) do
    with {schedulers, ""} <- Integer.parse(value) do
      ElixirDemo.Monitor.change_schedulers(schedulers)
      {:noreply, assign(socket, schedulers: schedulers)}
    end

    {:noreply, socket}
  end

  def handle_info(:update, socket) do
    {:noreply, update_stats(socket)}
  end

  def handle_info({:sum, pid, sum}, socket),
    do: {:noreply, update(socket, :operations, &set_result(&1, pid, sum))}

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket),
    do: {:noreply, update(socket, :operations, &set_result(&1, pid, :error))}

  defp start_sum(socket, str_input) do
    operation =
      case Integer.parse(str_input) do
        :error -> %{pid: nil, input: str_input, result: "invalid input"}
        {_input, remaining} when byte_size(remaining) > 0 -> %{pid: nil, input: str_input, result: "invalid input"}
        {input, ""} when input <= 0 -> %{pid: nil, input: input, result: "invalid input"}
        {input, ""} -> do_start_sum(input)
      end

    socket |> update(:operations, &[operation | &1]) |> assign(:number, changeset(0))
  end

  defp do_start_sum(input) do
    {:ok, pid} = ElixirDemo.Math.sum(input)
    %{pid: pid, input: input, result: :calculating}
  end

  defp set_result(operations, pid, result) do
    case Enum.split_with(operations, &match?(%{pid: ^pid, result: :calculating}, &1)) do
      {[operation], rest} -> [%{operation | result: result} | rest]
      _other -> operations
    end
  end

  defp changeset(value), do: Ecto.Changeset.cast({%{}, %{value: :integer}}, %{value: value}, [:value])

  defp calc_scheduler_graph(stats) do
    stats = Enum.reduce(stats, [], fn elem, acc -> [elem.schedulers_usage | acc] end) |> Enum.reverse()

    data_points =
      stats
      |> Stream.with_index(1)
      |> Enum.map(fn {usage, pos} -> %{x: (@num_points - pos) / @num_points, y: usage} end)

    legends = Enum.map([0, 25, 50, 75, 100], &%{title: "#{&1}%", at: &1 / 100})

    %{data_points: data_points, legends: legends}
  end

  defp calc_jobs_graph(stats) do
    stats = Enum.reduce(stats, [], fn elem, acc -> [elem.jobs_rate | acc] end) |> Enum.reverse()

    max_rate = Enum.max(stats)
    order_of_magnitude = if max_rate < 10, do: 1, else: round(:math.pow(10, floor(:math.log10(max_rate)) - 1))
    quantized_max_rate = max(round(max_rate / order_of_magnitude) * order_of_magnitude, 1)
    step = max(quantize(quantized_max_rate / 5, order_of_magnitude), 1)

    data_points =
      stats
      |> Stream.with_index(1)
      |> Enum.map(fn {jobs_rate, pos} -> %{x: (@num_points - pos) / @num_points, y: jobs_rate / max(max_rate, 1)} end)

    legends =
      0
      |> Stream.iterate(&(&1 + step))
      |> Stream.take_while(&(&1 <= max_rate))
      |> Enum.map(&%{title: title(&1), at: &1 / max(max_rate, 1)})

   %{data_points: data_points, legends: legends}
  end

  defp quantize(num, quant), do: round(num / quant) * quant
  defp title(num) when num > 0 and rem(num, 1000) == 0, do: "#{div(num, 1000)}k"
  defp title(num), do: num
end
