defmodule Rivet.Utils.Test do
  use ExUnit.Case

  doctest Rivet.Utils.Callbacks, import: true
  doctest Rivet.Utils.Codes, import: true
  doctest Rivet.Utils.Color, import: true
  doctest Rivet.Utils.Dig, import: true
  doctest Rivet.Utils.Enum, import: true
  doctest Rivet.Utils.List, import: true
  doctest Rivet.Utils.Math, import: true
  doctest Rivet.Utils.Redact, import: true
  doctest Rivet.Utils.Types, import: true
end
