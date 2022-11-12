defmodule Rivet.Utils.Color do
  @doc """
  iex> color = random_hex_color()
  iex> is_binary(color)
  true
  iex> String.length(color)
  7
  """
  def random_hex_color() do
    "#" <> Enum.map_join(0..5, fn _ -> Enum.random(0..15) |> Integer.to_string(16) end)
  end
end
