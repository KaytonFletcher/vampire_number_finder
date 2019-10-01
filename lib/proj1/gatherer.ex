defmodule Proj1.Gatherer do
  use GenServer
  @me Gatherer

  # api
  def start_link(worker_count) do
    GenServer.start_link(__MODULE__, worker_count, name: @me)
  end

  def done() do
    GenServer.cast(@me, :done)
  end

  def result(vampire_numbers) do
    GenServer.cast(@me, { :result, vampire_numbers })
  end

  # server
  def init(worker_count) do
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
    System.halt(0)
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
