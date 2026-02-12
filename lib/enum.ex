defmodule Rivet.Utils.Enum do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  @doc """
  like Enum.find_value() on a list of [{rx, fn}, ..], calling fn on the matched
  rx and returning the result.

  ```
  iex> opts = [
  ...>   {~r/^(\\d+)\\s*(m|min(s)?|minute(s)?)$/, fn match, _ -> {:min, match} end},
  ...>   {~r/^(\\d+)\\s*(h|hour(s)?|hr(s)?)$/, fn match, _ -> {:hr, match} end},
  ...> ]
  ...> enum_rx(opts, "30 m")
  {:min, ["30 m", "30", "m"]}
  iex> enum_rx(opts, "1.5 hr") # doesn't match because of the period
  nil
  ```
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
  map_while_ok maps then aggregates [{:ok, result1}, {:ok, result2}, ...] into {:ok, results}
  map_while_ok short circuits if an element maps to {:error, err}
  ```
  iex> map_while_ok([1,2,3], fn x -> {:ok, x + 1} end)
  {:ok, [2,3,4]}
  iex> map_while_ok([3,4,6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:ok, [3,4,6]}
  iex> map_while_ok([3,4,5,6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:error, "BAD"}
  ```
  """
  @spec map_while_ok(list(a), (a -> {:ok, b} | {:error, e})) :: {:error, e} | {:ok, list(b)}
        when a: term(), b: term(), e: term()
  @spec map_while_ok(list(a), list(b), (a -> {:ok, b} | {:error, e})) ::
          {:error, e} | {:ok, list(b)}
        when a: term(), b: term(), e: term()
  def map_while_ok(elems, fxn), do: map_while_ok(elems, [], fxn)

  def map_while_ok([next | tail], results, fxn) do
    with {:ok, result} <- fxn.(next),
         do: map_while_ok(tail, [result | results], fxn)
  end

  def map_while_ok([], results, _), do: {:ok, Enum.reverse(results)}

  @doc """
  ```
  iex> flat_map_while_ok([1,2,3], fn x -> {:ok, [x + 1]} end)
  {:ok, [2,3,4]}
  iex> flat_map_while_ok([3,4,6], fn 5 -> {:error, "BAD"}; x -> {:ok, [x]} end)
  {:ok, [3,4,6]}
  iex> flat_map_while_ok(["i", "i", "o"], fn x -> {:ok, ["e", x]} end)
  {:ok, ["e", "i", "e", "i", "e", "o"]}
  iex> flat_map_while_ok([3,4,5,6], fn 5 -> {:error, "BAD"}; x -> {:ok, [x]} end)
  {:error, "BAD"}
  ```
  """
  def flat_map_while_ok(elems, fxn), do: flat_map_while_ok(elems, [], fxn)

  def flat_map_while_ok([next | tail], acc, fxn) do
    with {:ok, results} <- fxn.(next),
         do: flat_map_while_ok(tail, reverse_concat(results, acc), fxn)
  end

  def flat_map_while_ok([], results, _), do: {:ok, Enum.reverse(results)}

  defp reverse_concat([head | tail], list), do: reverse_concat(tail, [head | list])
  defp reverse_concat([], list), do: list

  @doc """
  ```
  iex> reduce_while_ok([1,2,3], 0, fn x, acc -> {:ok, x + acc} end)
  {:ok, 6}
  iex> reduce_while_ok([1,2,-1,3], 0, fn -1, _ -> {:error, :out_of_bounds}; x, acc -> {:ok, x + acc};  end)
  {:error, :out_of_bounds}
  ```
  """
  def reduce_while_ok([next | tail], acc, fxn) do
    with {:ok, acc} <- fxn.(next, acc), do: reduce_while_ok(tail, acc, fxn)
  end

  def reduce_while_ok([], acc, _), do: {:ok, acc}

  @deprecated "Use map_while_ok/2 instead"
  def scmap(a, b), do: map_while_ok(a, b)

  @deprecated "Use map_while_ok/2 instead"
  def ok_map(a, b), do: map_while_ok(a, b)

  @deprecated "Use flat_map_while_ok/2 instead"
  def ok_flat_map(a, b), do: flat_map_while_ok(a, b)
end
