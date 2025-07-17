defmodule Rivet.Utils.Enum do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  @doc """
  like Enum.find_value() on a list of [{rx, fn}, ..], calling fn on the matched
  rx and returning the result.

  iex> opts = [
  ...>   {~r/^(\\d+)\\s*(m|min(s)?|minute(s)?)$/, fn match, _ -> {:min, match} end},
  ...>   {~r/^(\\d+)\\s*(h|hour(s)?|hr(s)?)$/, fn match, _ -> {:hr, match} end},
  ...> ]
  ...> enum_rx(opts, "30 m")
  {:min, ["30 m", "30", "m"]}
  iex> enum_rx(opts, "1.5 hr") # doesn't match because of the period
  nil
  """
  def enum_rx([], _str), do: nil

  def enum_rx(elems, str) do
    [elem | elems] = elems
    {rx, func} = elem

    case Regex.run(rx, str) do
      nil ->
        enum_rx(elems, str)

      match ->
        func.(match, str)
    end
  end

  @doc """
  short-circuit map:
  like regular map but short circuits if an element maps to {:error, err}

  iex> scmap([1,2,3], fn x -> {:ok, x + 1} end)
  {:ok, [2,3,4]}
  iex> scmap([3,4,6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:ok, [3,4,6]}
  iex> scmap([3,4,5,6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:error, "BAD"}

  """
  @spec scmap(list(a), list(b), (a -> {:ok, b} | {:error, e})) :: {:error, e} | {:ok, list(b)}
        when a: term(), b: term(), e: term()
  def scmap(elems, fxn), do: scmap(elems, [], fxn)

  def scmap([head | tail], results, fxn) do
    case fxn.(head) do
      {:ok, result} -> scmap(tail, [result | results], fxn)
      {:error, err} -> {:error, err}
    end
  end

  def scmap([], results, _), do: {:ok, Enum.reverse(results)}

  @doc """
  iex> pairs([])
  []
  iex> pairs(["a"])
  []
  iex> pairs([:a, :b])
  [{:a, :b}]
  iex> pairs([:a, :b])
  [{:a, :b}]
  iex> pairs([1,2,3])
  [{1, 2}, {1, 3}, {2, 3}]
  """
  def pairs([]), do: []
  def pairs([h | t]), do: Enum.map(t, fn v -> {h, v} end) ++ pairs(t)
end
