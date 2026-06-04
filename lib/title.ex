defmodule Rivet.Utils.Title do
  @skip ~w(a an the of in on and)

  def titleize(str) do
    str
    |> String.split()
    |> Enum.with_index()
    |> Enum.map(fn {word, i} ->
      if i > 0 and String.downcase(word) in @skip do
        String.downcase(word)
      else
        String.capitalize(word)
      end
    end)
    |> Enum.join(" ")
  end
end
