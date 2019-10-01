defmodule Proj1.RangeProvider do
  use GenServer
  @me PathFinder

  defp getBounds(lower, upper, amount) do
    getBounds([], lower, upper, amount)
  end

  defp getBounds(list, start, stop, amount) do
    if (stop - start <= amount) do [{start, stop} | list]
    else
      getBounds([{start, start+amount} | list], start+amount, stop, amount)
    end
  end

  def start_link(range) do
    GenServer.start_link(__MODULE__, range, name: @me)
  end

  def next_range() do
    GenServer.call(@me, :next_range)
  end

  def init({lower, upper}) do
    {:ok, getBounds(lower, upper, div(upper-lower, 8))}
  end

  def handle_call(:next_range, _from, ranges) do
    case ranges do
      [] -> {:reply, nil, []}
      [hd] ->{:reply, hd, []}
      [hd | tl] -> {:reply, hd, tl}
    end
  end
end
