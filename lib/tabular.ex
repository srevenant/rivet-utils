defmodule Rivet.Utils.Tabular do
  @moduledoc """
  converts list of keywords into text-based table

  for example
  tabularize([[a: "cat", b: "dog"], [a: "horse", b: "mouse"]])

  A     | B
  ----- | ------
  cat   | dog
  horse | mouse

  Contributor: Jake Wood
  """

  def tabularize([]), do: ""

  def tabularize([head | _] = keywords) when is_list(keywords) do
    init = Enum.map(head, fn {key, _} -> String.length(Atom.to_string(key)) end)

    widths =
      Enum.reduce(keywords, init, fn counts, row ->
        Enum.zip_with([counts, row], fn [{_, val}, count] ->
          Enum.max([String.length("#{val}"), count])
        end)
      end)

    header =
      Enum.map(head, fn {key, _} ->
        {nil, Atom.to_string(key) |> String.upcase() |> String.replace("_", " ")}
      end)

    subhead = Enum.map(widths, fn width -> {nil, String.duplicate("-", width)} end)
    table = [header | [subhead | keywords]]

    Enum.map_join(
      table,
      "\n",
      fn row ->
        Enum.zip(row, widths)
        |> Enum.map_join(
          " | ",
          fn {{_, val}, width} -> String.pad_trailing(val, width) end
        )
        |> String.trim_trailing()
      end
    )
  end
end
