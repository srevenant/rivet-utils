defmodule Rivet.Utils.Math do
  @doc """
  iex> average([])
  0.0
  iex> average([30])
  30.0
  iex> average([30, 32, 20, 18, 23, 26, 27])
  25.142857142857142
  """
  def average([]), do: 0.0

  def average(list),
    do: Enum.sum(list) / length(list)

  @doc """
  iex> stddev([])
  0.0
  iex> stddev([30])
  0.0
  iex> stddev([2, 4, 4, 4, 5, 5, 7, 9])
  2.0
  """
  def stddev(list) do
    mean = average(list)

    variance =
      Enum.map(list, &deviation(&1, mean))
      |> average()

    Float.pow(variance, 0.5)
  end

  def deviation(value, mean), do: Float.pow(value - mean, 2)

  @doc """
  iex> ranges_overlap?(0, 2, 1, 3)
  true
  iex> ranges_overlap?(-3, 10, 1, 4)
  true
  iex> ranges_overlap?(5, 6, 3, 7)
  true
  iex> ranges_overlap?(3, 10, 1, 4)
  true
  iex> ranges_overlap?(-1, 1, 1, 2)
  false
  iex> ranges_overlap?(10, 11, 8, 10)
  false
  iex> ranges_overlap?(1, 2, 1, 2)
  true
  """
  @spec ranges_overlap?(number(), number(), number(), number()) :: boolean()
  def ranges_overlap?(a1, a2, b1, b2), do: max(a1, b1) < min(a2, b2)
end
