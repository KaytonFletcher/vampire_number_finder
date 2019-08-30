defmodule FangFinder do
  use Task

  # base case for empty list
  def permutations([], _n), do: [[]]
  # base case for zero-length permutation
  def permutations(_li, 0), do: [[]]

  def permutations(li, n), do: for hd <- li, tl <- permutations(li -- [hd], n-1), do: [hd | tl]

  defp isVampire?(num) do
    if(num < 1000) do false
    else
      digits = Integer.digits num
      len = length(digits)
      if(rem(len, 2) != 0) do false
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
        else false end
      end
    end
  end

  def findVampireNumbers(range) do
    Enum.reduce(range, [], fn (num, list) ->
      case isVampire?(num) do
        false -> list
        map_set -> [map_set | list]
      end
    end)
  end

  # called after start_link
  def run({lower, upper}) do
    findVampireNumbers(lower..upper)
  end
end

defmodule Entry do

  defp pretty_print(result) do
    case result do
      [] -> nil
      [hd] -> IO.puts(Enum.join(hd, " "))
      [ hd | tl] ->
        pretty_print [hd]
        pretty_print tl
    end
  end

  defp getBounds(lower, upper, amount) do
    getBounds([], lower, upper, amount)
  end

  defp getBounds(list, start, stop, amount) do
    if (stop - start <= amount) do [{start, stop} | list]
    else
      getBounds([{start, start+amount} | list], start+amount, stop, amount)
    end
  end

  def main do
    if(length(System.argv()) == 2) do

      {lower, _res} = Integer.parse List.first(System.argv())
      {upper, _res} = Integer.parse List.last(System.argv())

      if(lower <= upper) do
        Supervisor.start_link([{Task.Supervisor, name: FangManager}], strategy: :one_for_one)
        Task.Supervisor.async_stream(FangManager, getBounds(lower, upper, div(upper-lower,10)), FangFinder, :run, [], timeout: 20000)
        |> Enum.flat_map(fn({:ok, result}) -> result end)
        |> pretty_print
      else
        IO.puts("bad range, provide lower number first")
      end
    else
      IO.puts("wrong number of arguments, provide 2")
    end
  end
end

Entry.main()
