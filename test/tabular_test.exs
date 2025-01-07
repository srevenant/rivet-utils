defmodule Rivet.Utils.TabularTest do
  use ExUnit.Case
  alias Rivet.Utils.Tabular

  describe "tabular" do
    test "tabularize" do
      assert """
             A          | B     | C
             ---------- | ----- | -----------
             lorem      | ipsum | dolor
             sit        | amet  | consectetur
             adipiscing | sed   | eiusmod
             """ =
               Tabular.tabularize([
                 [a: "lorem", b: "ipsum", c: "dolor"],
                 [a: "sit", b: "amet", c: "consectetur"],
                 [a: "adipiscing", b: "sed", c: "eiusmod"]
               ]) <> "\n"

      assert """
             X  | Y  | C
             -- | -- | --
             lo | ip | do
             si | am | co
             """ =
               Tabular.tabularize([
                 [x: "lo", y: "ip", C: "do"],
                 [x: "si", b: "am", C: "co"]
               ]) <> "\n"

      assert """
             I | J
             - | -
             a | b
             """ = Tabular.tabularize([[i: "a", j: "b"]]) <> "\n"

      assert is_nil(Tabular.tabularize([]))
    end
  end
end
