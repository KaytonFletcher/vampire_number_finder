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

    # Server
    def init(:no_args) do
      { :ok, []}
    end

    def handle_call(:get, _from, vampire_numbers) do
      { :reply, vampire_numbers, vampire_numbers}
    end

    def handle_cast({ :add, new_numbers }, vampire_numbers) do
      case new_numbers do
        [] -> { :noreply, vampire_numbers}
        list -> {:noreply, list ++ vampire_numbers}
      end
    end

  end
