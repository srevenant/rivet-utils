defmodule Rivet.Utils.Callbacks do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  @doc """
  ```elixir
  iex> %{red: func} = init_callbacks([:red])
  %{red: func}
  iex> init_callbacks(nil)
  nil
  ```
  """
  def init_callbacks(nil), do: nil

  def init_callbacks(list), do: Enum.reduce(list, %{}, &put_callback(&2, &1))

  @doc """
  ```elixir
  iex> do_callback(%{callbacks: nil}, nil, nil)
  :error
  iex> do_callback(%{callbacks: %{mine: fn _, x -> {:ok, x} end}}, :mine, :narf)
  {:ok, :narf}
  iex> do_callback(%{callbacks: %{not: fn _, x -> x end}}, :diff, :narf)
  :error
  iex> do_callback(nil, :diff, :narf)
  :error
  ```
  """
  @spec do_callback(%{callbacks: map()} | map(), atom(), term()) :: :error | {:ok, term()}
  def do_callback(%{callbacks: nil}, _, _), do: :error

  def do_callback(nil, _, _), do: :error

  def do_callback(%{callbacks: callbacks}, a, b), do: do_callback(callbacks, a, b)

  def do_callback(callbacks, callback, arg) when is_atom(callback) do
    case Map.get(callbacks, callback) do
      nil ->
        :error

      cbfunc ->
        cbfunc.(self(), arg)
    end
  end

  @doc """
  ```elixir
  iex> %{thisone: func} = put_callback(%{}, :thisone)
  ...> is_function(func)
  true
  ```
  """
  @spec put_callback(map(), atom()) :: map()
  def put_callback(callbacks, key) do
    pid = self()
    Map.put(callbacks, key, fn from, arg -> send(pid, {key, arg, from}) end)
  end

  @doc """
  ```elixir
  iex> take_callbacks(%{callbacks: %{one: 1, two: 2}}, [:two])
  %{two: 2}
  iex> take_callbacks(%{callbacks: %{one: 1, two: 2}}, [])
  nil
  ```
  """
  @spec take_callbacks(map(), list()) :: map()
  def take_callbacks(%{callbacks: callbacks}, only) do
    result = Map.take(callbacks, only)
    if map_size(result) == 0, do: nil, else: result
  end
end
