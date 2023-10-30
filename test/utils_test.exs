defmodule Rivet.Utils.Test do
  use ExUnit.Case

  doctest Rivet.Utils.Callbacks, import: true
  doctest Rivet.Utils.Codes, import: true
  # doctest Rivet.Utils.Color, import: true
  doctest Rivet.Utils.Dig, import: true
  doctest Rivet.Utils.Enum, import: true
  doctest Rivet.Utils.List, import: true
  doctest Rivet.Utils.Math, import: true
  doctest Rivet.Utils.Redact, import: true

  describe "random/0" do
    test "returns a random string of 72 characters" do
      first_string = Rivet.Utils.RandChars.random()
      second_string = Rivet.Utils.RandChars.random()

      assert String.length(first_string) == 72
      refute first_string == second_string
    end
  end
end
