defmodule Proj1.RangeProviderTest do
  use ExUnit.Case
  alias Proj1.RangeProvider

  # assumes command line args of {1000, 2000}
  test "can retrieve next range to compute" do
    assert RangeProvider.next_range() == {1875, 2000}
  end
end
