defmodule Proj1.ResultsTest do
  use ExUnit.Case
  alias Proj1.Results
  test "can add numbers to results" do
    Results.add_vampire_numbers([123, 48, 16])
    Results.add_vampire_numbers([17])
    assert Results.get_vampire_numbers() == [[17],[123, 48, 16]]
  end
end
