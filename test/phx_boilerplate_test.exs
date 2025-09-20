defmodule PhxBoilerplateTest do
  use ExUnit.Case
  doctest PhxBoilerplate

  test "greets the world" do
    assert PhxBoilerplate.hello() == :world
  end
end
