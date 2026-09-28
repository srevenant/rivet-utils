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
  iex> map_while_ok([], &(&1))
  {:ok, []}
  iex> {:ok, results} = map_while_ok(%{a: 1, b: 2}, fn {_, v} -> {:ok, v} end)
  iex> Enum.sort(results)
  [1,2]
  iex> map_while_ok(%{a: 1, b: 2}, fn {:b, _} -> {:error, :bad_key}; {_, v} -> {:ok, v} end)
  {:error, :bad_key}
  iex> map_while_ok(1..6, fn x -> {:ok, x} end)
  {:ok, [1,2,3,4,5,6]}
  iex> map_while_ok(0..100_000_000, fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:error, "BAD"}
  ```
  """

  @spec map_while_ok(Enumerable.t(), (any -> {:ok, any} | {:error, any})) ::
          {:ok, list} | {:error, any}
  def map_while_ok(elems, fxn) do
    reducer = fn elem, results ->
      with {:ok, result} <- fxn.(elem), do: {:ok, [result | results]}
    end

    with {:ok, results} <- reduce_while_ok(elems, [], reducer),
         do: {:ok, Enum.reverse(results)}
  end

  @doc """
  ```
  iex> map_only_ok([{:ok, 1}, {:error, "bad"}, {:ok, 2}, {:error, "bad"}], &(&1))
  {:ok, [1, 2]}
  iex> map_only_ok([3, 4, 5, 6], fn 5 -> {:error, "BAD"}; x -> {:ok, x} end)
  {:ok, [3, 4, 6]}
  iex> map_only_ok([], &(&1))
  {:ok, []}
  ```
  """
  @spec map_only_ok(Enumerable.t(), (any -> {:ok, any} | {:error, any})) :: {:ok, list}
  def map_only_ok(elems, fxn) do
    reducer = fn elem, results ->
      case fxn.(elem) do
        {:ok, result} -> {:ok, [result | results]}
        {:error, _} -> {:ok, results}
      end
    end

    with {:ok, results} <- reduce_while_ok(elems, [], reducer),
         do: {:ok, Enum.reverse(results)}
  end

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
  iex> flat_map_while_ok([], &(&1))
  {:ok, []}
  ```
  """
  @spec flat_map_while_ok(Enumerable.t(), (any -> {:ok, list(any)} | {:error, any})) ::
          {:ok, list} | {:error, any}
  def flat_map_while_ok(elems, fxn) do
    reducer = fn elem, results ->
      with {:ok, result} <- fxn.(elem), do: {:ok, reverse_concat(result, results)}
    end

    with {:ok, results} <- reduce_while_ok(elems, [], reducer),
         do: {:ok, Enum.reverse(results)}
  end

  @spec reverse_concat(list(a), list(a)) :: list(a) when a: term()
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
  def reduce_while_ok(elems, init, fxn) do
    Enum.reduce_while(elems, {:ok, init}, fn elem, {:ok, acc} ->
      case fxn.(elem, acc) do
        {:ok, _} = result -> {:cont, result}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @deprecated "Use map_while_ok/2 instead"
  def scmap(a, b), do: map_while_ok(a, b)

  @deprecated "Use map_while_ok/2 instead"
  def ok_map(a, b), do: map_while_ok(a, b)

  @deprecated "Use flat_map_while_ok/2 instead"
  def ok_flat_map(a, b), do: flat_map_while_ok(a, b)
end
