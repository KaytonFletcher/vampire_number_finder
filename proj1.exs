defmodule Proj1 do

  def start() do
    if(length(System.argv()) == 2) do

      {lower, _res} = Integer.parse List.first(System.argv())
      {upper, _res} = Integer.parse List.last(System.argv())

      if(lower <= upper) do

        children = [
          Proj1.Results,
          { Proj1.RangeProvider, {lower, upper} },
          Proj1.WorkerSupervisor,
          { Proj1.Gatherer, 8 }
        ]

        opts = [strategy: :one_for_all, name: Proj1.Supervisor]
        {:ok, pid} = Supervisor.start_link(children, opts)

        Process.monitor(pid)

        # makes sure the mix run process waits for the proj1 supervisor to complete, simulating an iex session or the --no-halt flag
        receive do
          {:DOWN, _ref, :process, _object, _reason} ->
            nil
        end

      else
        IO.puts("bad range, provide lower number first")
      end

    else
      IO.puts("wrong number of arguments, provide 2")
    end
  end
end

### THIS MODULE TAKES IN {LOWER, UPPER} AND MAKES [[] [] [] [] [] [] [] []] (List of 8 lists) ###
### Where each inner list has an equally sized sub-range of lower-upper to give to a worker ###
# I chose 8 due to the number of cores my computer has, and spawn 8 workers as well
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
    #Fixes infinite loop caused by providing a small range < 8
    range_size =
    case div(upper-lower, 8) do
      0 -> 1
      num -> num
    end
    {:ok, getBounds(lower, upper, range_size)}
  end

  def handle_call(:next_range, _from, ranges) do
    case ranges do
      [] -> {:reply, nil, []}
      [hd] ->{:reply, hd, []}
      [hd | tl] -> {:reply, hd, tl}
    end
  end
end


defmodule Proj1.Results do
  use GenServer
  @me __MODULE__

    def start_link(_) do
      GenServer.start_link(__MODULE__, :no_args, name: @me)
    end

    def get_vampire_numbers() do
      GenServer.call(@me, :get)
    end

    def add_vampire_numbers(vampire_numbers) do
      GenServer.cast(@me, {:add, vampire_numbers})
    end

    def init(:no_args) do
      { :ok, []}
    end

    def handle_call(:get, _from, vampire_numbers) do
      { :reply, vampire_numbers, vampire_numbers}
    end

    def handle_cast({ :add, new_numbers }, vampire_numbers) do
      case new_numbers do
        [] -> { :noreply, vampire_numbers}
        list -> {:noreply, list ++ vampire_numbers} # Becomes a list of vampire number lists [[1260 21 60], [1530 30 51], etc...]
      end
    end

  end


defmodule Proj1.Gatherer do
  use GenServer
  @me Gatherer

  def start_link(worker_count) do
    GenServer.start_link(__MODULE__, worker_count, name: @me)
  end

  def done() do
    GenServer.cast(@me, :done)
  end

  def result(vampire_numbers) do
    GenServer.cast(@me, { :result, vampire_numbers })
  end

  def init(worker_count) do
    # send after 0 ms waits for server to be initialized, and then sends request to self
    Process.send_after(self(), :start_workers, 0)
    { :ok, worker_count }
  end

  def handle_info(:start_workers, worker_count) do
    1..worker_count
    |> Enum.each(fn _ -> Proj1.WorkerSupervisor.add_worker() end)
    { :noreply, worker_count }
  end

  def handle_cast(:done, _worker_count = 1) do
    print_results()
    #manually halts program once there are no more workers
    System.halt(0)
    #{:noreply, 1}
  end

  def handle_cast(:done, worker_count) do
    { :noreply, worker_count - 1 }
  end

  def handle_cast({:result, vampire_numbers}, worker_count) do
    Proj1.Results.add_vampire_numbers(vampire_numbers)
    { :noreply, worker_count }
  end

  defp print_results() do
    Proj1.Results.get_vampire_numbers()
    |> pretty_print
  end

  # Prints list of lists of form [num fang1_1 fang1_2 fang2_1 fang2_2]
  defp pretty_print(result) do
    case result do
      [] -> nil
      [hd] -> IO.puts(Enum.join(hd, " "))
      [ hd | tl] ->
        pretty_print [hd]
        pretty_print tl
    end
  end
end


defmodule Proj1.WorkerSupervisor do
  use DynamicSupervisor
  @me WorkerSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @me)
  end

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_worker() do
    {:ok, _pid} = DynamicSupervisor.start_child(@me, Proj1.Worker)
  end
end


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

  #
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

Proj1.start()
