defmodule Rivet.Utils.List do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  @doc """
  Inefficient but simple set operations.

  Maintains order, returns a list, uses a "getter" function to pull the value

  iex> setadd([1,2,3], 3, &(&1))
  [1,2,3]
  iex> setadd([1,2,3], 4, &(&1))
  [1,2,3,4]
  """
  def setadd(list, elem, getter) do
    check_elem = getter.(elem)

    if is_nil(Enum.find(list, fn e -> getter.(e) == check_elem end)) do
      list ++ [elem]
    else
      list
    end
  end

  @doc """
  Inefficient but simple set operations.

  Maintains order, returns a list, uses a "getter" function to pull the value

  iex> setremove([1,2,3], 3, &(&1))
  [1,2]
  iex> setremove([1,2,3], 4, &(&1))
  [1,2,3]
  """
  def setremove(list, elem, getter) do
    check_elem = getter.(elem)
    Enum.filter(list, fn e -> getter.(e) != check_elem end)
  end

  @doc """

  # TODO: switch to Enum.take()

  iex> trim([1,2,3,4,5], 3)
  [1,2,3]
  iex> trim([1,2,3,4], 10)
  [1,2,3,4]
  iex> trim([1,2,3,4,5], 0)
  []
  """
  def trim(list, length) do
    if length(list) > length do
      pop(list) |> trim(length)
    else
      list
    end
  end

  @doc """
  iex> pop([1,2,3,4,5])
  [1,2,3,4]
  """
  def pop(list), do: list |> :lists.reverse() |> tl() |> :lists.reverse()

  @doc """
  iex> put_different([], 20, 10, :last_off)
  [last_off: 10]
  iex> put_different([], 10, 10, :last_off)
  []
  """
  def put_different(chgs, same, same, _), do: chgs
  def put_different(chgs, _old, new, key), do: [{key, new} | chgs]
end
