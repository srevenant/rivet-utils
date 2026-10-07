defmodule Rivet.Utils.Ranges do
  import Transmogrify.As

  @doc """
  iex> expand(["70-72, 3,2-5, 80"])
  [2, 3, 4, 5, 70, 71, 72, 80]
  """
  # some sugar to make calling it easier
  def expand([_ | _] = list), do: expand(Enum.join(list, ","))

  def expand(str) do
    str
    |> String.split(~r/\s*,\s*/, trim: true)
    |> Enum.flat_map(&expand_/1)
    |> in_order()
  end

  defp expand_(str) do
    case Regex.split(~r/\s*-\s*/, str, trim: true) do
      [a, b] -> Enum.to_list(as_int!(a)..as_int!(b))
      [a] -> [as_int!(a)]
    end
  end

  @doc """
  iex> collapse([])
  ""
  iex> collapse([2, 3, 4, 5, 70, 71, 72, 80], ";")
  "2-5;70-72;80"
  """
  def collapse(numbers, delim \\ ", ") do
    numbers
    |> in_order()
    |> group_ranges()
    |> Enum.map_join(delim, &format_range/1)
  end

  def in_order(list), do: MapSet.new(list) |> MapSet.to_list() |> Enum.sort()

  ################################################################################
  # switch to larger reducer
  defp group_ranges([first | rest]), do: group_ranges_(rest, first, first, [])

  # no inputs, just return nothing
  defp group_ranges([]), do: []

  ################################################################################
  # keep incrementing until we reach the end of this run
  defp group_ranges_([next | rest], start, prev, out) when next == prev + 1,
    do: group_ranges_(rest, start, next, out)

  # we're at the end of this run, push it off and start over
  defp group_ranges_([next | rest], start, prev, out),
    do: group_ranges_(rest, next, next, [{start, prev} | out])

  defp group_ranges_([], start, prev, out), do: Enum.reverse([{start, prev} | out])

  ################################################################################
  defp format_range({a, b}) when a == b, do: "#{a}"
  defp format_range({a, b}), do: "#{a}-#{b}"
end
