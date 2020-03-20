defmodule ElixirDemoWeb.PageView do
  use ElixirDemoWeb, :view

  def data_points(graph) do
    graph.data_points
    |> Stream.map(&"#{x(&1.x)},#{y(&1.y)}")
    |> Enum.join(" ")
  end

  def graph_width(), do: 600
  def graph_height(), do: 500

  def x(relative_x), do: min(round(relative_x * graph_width()), graph_width())
  def y(relative_y), do: graph_height() - min(round(relative_y * graph_height()), graph_height())
end
