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
  ok_map maps then aggregates [{:ok, result1}, {:ok, result2}, ...] into {:ok, results}
  ok_map short circuits if an element maps to {:error, err}
  ```
  iex> ok_map([1,2,3], fn x -> {:ok, x + 1} end)
  {:ok, [2,3,4]}
  iex> ok_map([3,4,6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:ok, [3,4,6]}
  iex> ok_map([3,4,5,6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:error, "BAD"}
  ```

  """
  @spec ok_map(list(a), list(b), (a -> {:ok, b} | {:error, e})) :: {:error, e} | {:ok, list(b)}
        when a: term(), b: term(), e: term()
  def ok_map(elems, fxn), do: ok_map(elems, [], fxn)

  def ok_map([head | tail], results, fxn) do
    case fxn.(head) do
      {:ok, result} -> ok_map(tail, [result | results], fxn)
      {:error, err} -> {:error, err}
    end
  end

  def ok_map([], results, _), do: {:ok, Enum.reverse(results)}

  @doc """
  ```
  iex> ok_flat_map([1,2,3], fn x -> {:ok, [x + 1]} end)
  {:ok, [2,3,4]}
  iex> ok_flat_map([3,4,6], fn 5 -> {:error, "BAD"}; x -> {:ok, [x]} end)
  {:ok, [3,4,6]}
  iex> ok_flat_map([3,4,5,6], fn 5 -> {:error, "BAD"}; x -> {:ok, [x]} end)
  {:error, "BAD"}
  ```
  """
  def ok_flat_map(a, b),
    do: with({:ok, results} <- ok_map(a, b), do: {:ok, List.flatten(results)})

  @deprecated "Use ok_map/2 instead"
  def scmap(a, b), do: ok_map(a, b)
end
