defmodule FangManager do
  use Supervisor
  def start_link(range) do
    Supervisor.start_link(__MODULE__, range)
  end


  def init({lower, upper}) do
    children = Enum.map(Enum.chunk_every(lower..upper,div(upper-lower, 5)), fn(range) ->
      {FangFinder, [range]}
    end)
    IO.inspect(length(children), label: "Number of children")
    Supervisor.init(children, strategy: :one_for_one)
  end

  def getAllNumbers(children) do
    Enum.each(children, fn {_id, child, _type, _modules}->
      IO.inspect(child, label: "Sending message to")
      GenServer.cast(child, :find_numbers)
    end)
  end
end

defmodule FangFinder do
  use GenServer

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
        if(MapSet.size(solution) != 0 ) do solution
        else false end
      end
    end
  end

  def findVampireNumbers(range) do
    numbersFound =
    Enum.reduce(range, 0, fn(num, acc) ->
      case isVampire?(num) do
        false -> acc
        mapset -> IO.puts("#{num} ")
         Enum.each(mapset, fn n1 -> IO.puts("#{n1} #{div(num, n1)} ") end)
         acc + 1
      end
    end)

    IO.inspect(numbersFound, label: "Numbers Found")
  end

  # defines how each worker will start
  def child_spec(range) do
    %{
      id: List.first(range),
      start: {FangFinder, :start_link, range}
    }
  end

  # called on worker start up, tasked with a specific range of numbers
  def start_link(range) do
    # IO.inspect(self(), label: "In start link, calling spawn_link")
    {:ok, pid} = GenServer.start_link(__MODULE__, range, [debug: [:trace]])
  end

  # called after start_link
  @impl true
  def init(range) do
    IO.inspect(self(), label: "Initialized")

    # returns success with state = range to compute
    {:ok, range}
  end

  @impl true
  def handle_cast(:find_numbers, range) do
    IO.inspect(range, label: "Finding numbers")
    findVampireNumbers(range)
    IO.puts("finished finding numbers")
    {:stop, "Task completed", []}
  end

end

defmodule Entry do
def main do
  if(length(System.argv()) == 2) do

    {lower, _res} = Integer.parse List.first(System.argv())
    {upper, _res} = Integer.parse List.last(System.argv())

    if(lower <= upper) do
      {:ok, pid} = FangManager.start_link({lower, upper})


      Process.monitor(pid)
      FangManager.getAllNumbers(Supervisor.which_children(pid))

      receive do
        msg -> IO.puts(msg)
      end

      #USED FOR SINGLE PROCESS RUN
      #FangFinder.findVampireNumbers(lower..upper)
    else
      IO.puts("bad range, provide lower number first")
    end

  else
    IO.puts("wrong number of arguments, provide 2")
  end
end
end

Entry.main()
