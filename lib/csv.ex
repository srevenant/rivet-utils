defmodule Rivet.Utils.CSV do
  @moduledoc """
  lift the hood on the CSV module and call some of it's internal
  parsing, as we aren't using it's higher level streams

  Contributor: Brandon Gillespie
  """

  @doc """
  iex> parse_line("this,that,line,10,3.14")
  ["this", "that", "line", 10, 3.14]
  """
  def parse_line(line) do
    with [ok: parsed] <- CSV.decode([line]) |> Enum.take(1) do
      Enum.map(parsed, fn e ->
        func =
          if String.contains?(e, "."),
            do: &Rivet.Utils.Types.as_float/1,
            else: &Rivet.Utils.Types.as_int/1

        case func.(e) do
          {:ok, val} -> val
          {:error, _} -> e
        end
      end)
    end
  end
end
