defmodule Proj1 do
  @moduledoc """
  Documentation for Proj1.
  """

  # base case for empty list
  def permutations([], _n), do: []
  # base case for zero-length permutation
  def permutations(_li, 0), do: []

  def permutations(li, n), do: for hd <- li, tl <- permutations(li, n-1), do: [hd | tl]

  def start do
    if(length(System.argv()) == 2) do
      IO.inspect System.argv()
    else
      IO.puts("Bad Arguments")
    end
  end
end

Proj1.start()
