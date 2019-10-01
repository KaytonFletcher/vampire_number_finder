defmodule Proj1.Application do
  use Application

  def start(_type, _args) do

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

        # makes sure the mix run process waits for the proj1 supervisor to complete,
        # simulating an iex session or the --no-halt flag

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
