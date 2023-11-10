defmodule EctoContractTest do
  use ExUnit.Case
  doctest EctoContract

  test "greets the world" do
    assert EctoContract.hello() == :world
  end
end
