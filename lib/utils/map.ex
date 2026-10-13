defmodule Rivet.Utils.Map do
  @doc """
  iex> to_string_keqv(%{a: 10, b: "narf"})
  "a=10 b=narf"
  """
  def to_string_keqv(kvs) do
    Rivet.Utils.UniformLogFormat.format_msg(kvs, nil)
    |> IO.iodata_to_binary()
    # format_msg prefixes a space we don't want
    |> String.slice(1..-1//1)
  end
end
