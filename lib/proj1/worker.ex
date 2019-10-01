defmodule Proj1.Worker do
  use GenServer, restart: :transient

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    Process.send_after(self(), :find_vampire_numbers, 0)
    { :ok, nil }
  end

  def handle_info(:find_vampire_numbers, _) do
    Proj1.RangeProvider.next_range()
    |> find_vampire_numbers()
    |> add_result()
  end

  # If there are no more ranges to compute
  defp add_result(nil) do
    Proj1.Gatherer.done()
    {:stop, :normal, nil}
  end

  defp add_result(vampire_numbers) do
    Proj1.Gatherer.result(vampire_numbers)
    send(self(), :find_vampire_numbers)
    { :noreply, nil }
  end

    # base case for empty list
    defp permutations([], _n), do: [[]]

    # base case for zero-length permutation
    defp permutations(_li, 0), do: [[]]

    defp permutations(li, n), do: for hd <- li, tl <- permutations(li -- [hd], n-1), do: [hd | tl]

    defp find_vampire(num) do
      if(num < 1000) do nil
      else
        digits = Integer.digits num
        len = length(digits)
        if(rem(len, 2) != 0) do nil
        else
          solution =
          for perm1 <- permutations(digits, div(len,2)),
            perm2 <- permutations(digits -- perm1, div(len,2)),
              List.first(perm1) != 0,
              List.first(perm2) != 0,
              (List.last(perm1) != 0 || List.last(perm2) != 0),
              n1 = Integer.undigits(perm1),
              n2 = Integer.undigits(perm2),
              n1 - n2 >= 0,
              (n1 * n2 == num),
              into: MapSet.new
            #adds n1 to set, sets can't have duplicates which illiminates some of the permutations
             do n1 end

           #if set is not empty, return set, it is a vampire number
          if(MapSet.size(solution) != 0 ) do
            [num |
              Enum.reduce(solution, [], fn fang, list ->
                 [div(num, fang) | [fang | list]]
              end)]
          else nil end
        end
      end
    end

    defp find_vampire_numbers(nil), do: nil

    defp find_vampire_numbers({lower, upper}) do
      Enum.reduce(lower..upper, [], fn (num, list) ->
        case find_vampire(num) do
          nil -> list
          map_set -> [map_set | list]
        end
      end)
    end
end
