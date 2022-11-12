defmodule Rivet.Utils.Types do
  @moduledoc """
  Helper module for common type handling needs

  Contributors: Brandon Gillespie, Mark Erickson, Lyle Mantooth
  """

  @doc """
  ```elixir
  iex> lookup_address("127.0.0.1")
  {:ok, {127,0,0,1}}
  ```
  """
  @spec lookup_address(String.t()) :: {:ok, tuple()} | {:error, term()}
  def lookup_address(address) do
    address = to_charlist(address)

    # parse_address/1 returns {:ok, ip} if successful. If there's an error,
    # `address` is probably a hostname.
    with {:error, :einval} <- :inet.parse_address(address),
         {:ok, {:hostent, ^address, _, _, _, [ip | _]}} <- :inet.gethostbyname(address) do
      {:ok, ip}
    end
  end

  @doc ~S"""
  ```elixir
  iex> as_int(10)
  {:ok, 10}
  iex> as_int("10")
  {:ok, 10}
  iex> as_int("tardis")
  {:error, "\"tardis\" is not a number"}
  iex> as_int(:foo)
  {:error, ":foo is not a number"}
  ```
  """
  def as_int(arg) when is_integer(arg), do: {:ok, arg}

  def as_int(arg) when is_binary(arg) do
    {:ok, String.to_integer(arg)}
  rescue
    ArgumentError -> {:error, "#{inspect(arg)} is not a number"}
  end

  def as_int(other), do: {:error, "#{inspect(other)} is not a number"}

  @doc ~S"""
  ```elixir
  iex> as_int!(10)
  10
  iex> as_int!("10")
  10
  iex> as_int!("tardis", 9)
  9
  iex> as_int!(:foo, 8)
  8
  ```
  """
  def as_int!(arg, default \\ 0) do
    case as_int(arg) do
      {:ok, num} -> num
      {:error, _} -> default
    end
  end

  @doc ~S"""
  ```elixir
  iex> as_float(10.52)
  {:ok, 10.52}
  iex> as_float("10.5")
  {:ok, 10.5}
  iex> as_float(".55")
  {:ok, 0.55}
  iex> as_float("tardis")
  {:error, "\"tardis\" is not a number"}
  ```
  """
  def as_float(arg) when is_number(arg), do: {:ok, arg}

  def as_float(arg) when is_binary(arg) do
    {:ok, String.to_float(arg)}
  rescue
    ArgumentError ->
      if String.at(arg, 0) == "." do
        as_float("0#{arg}")
      else
        as_int(arg)
      end
  end

  @doc ~S"""
  ```elixir
  iex> as_float!(10.0)
  10.0
  iex> as_float!("10.0")
  10.0
  iex> as_float!("tardis", 9.0)
  9.0
  ```
  """
  def as_float!(arg, default \\ 0.0) do
    case as_float(arg) do
      {:ok, num} -> num
      {:error, _} -> default
    end
  end

  @doc """
  Iterate a map and merge string & atom keys into just strings.

  Not recursive, only top level.

  Behavior with mixed keys being merged is not guaranteed, as maps are not always
  ordered.

  ## Examples

      iex> string_keys(%{tardis: 1, is: 2, color: "blue"})
      %{"tardis" => 1, "is" => 2, "color" => "blue"}

  """
  def string_keys(map) do
    for {key, val} <- map, into: %{} do
      if is_atom(key),
        do: {to_string(key), val},
        else: {key, val}
    end
  end

  @doc """
  Polymorphic conversion of data into an atom.

  If using, make sure inputs being called are not using user-submitted data, or
  be vulnerable to exhausting the atoms table.

  ```elixir
  iex> as_atom("long ugly thing prolly")
  :"long ugly thing prolly"
  iex> as_atom("as_atom")
  :as_atom
  iex> as_atom(:atom)
  :atom
  iex> as_atom(["as_atom", "another"])
  [:as_atom, :another]
  iex> as_atom({:fugly})
  :"{:fugly}"
  ```
  """
  def as_atom(str) when is_binary(str) do
    String.to_atom(str)
  end

  def as_atom(list) when is_list(list) do
    Enum.map(list, fn key -> as_atom(key) end)
  end

  def as_atom(key) when is_atom(key), do: key

  def as_atom(other) do
    any_to_string(other) |> String.to_atom()
  end

  ################################################################################
  @doc """
  Lowercase, Snakecase atom, from string or atom

  ```elixir
  iex> clean_atom(:value)
  :value
  iex> clean_atom(:Value)
  :value
  iex> clean_atom("valueCamelToSnake")
  :value_camel_to_snake
  iex> clean_atom(:"value-dashed")
  :value_dashed
  iex> clean_atom("Value-Dashed")
  :value_dashed
  iex> clean_atom({:narf})
  {:narf}
  ```
  """
  def clean_atom(value) when is_atom(value) do
    clean_atom(Atom.to_string(value))
  end

  def clean_atom(value) when is_binary(value) do
    value
    |> Transmogrify.snakecase()
    |> as_atom
  end

  def clean_atom(value), do: value

  ################################################################################

  @doc """

  iex> map_to_kvstr(%{a: "b", c: "10", d: "longer with space"})
  to_string('a=b c=10 d="longer with space"')
  """
  def map_to_kvstr(map) do
    Enum.map_join(map, " ", fn {k, v} ->
      [any_to_string(k), "=", any_to_string(v)]
    end)
  end

  defp json_safe_string(str) when is_binary(str) do
    if String.contains?(str, " ") or String.contains?(str, "\"") do
      "#{inspect(str)}"
    else
      to_string(str)
    end
  end

  # TODO:  how much of this is still needed today?
  defp any_to_string(pid) when is_pid(pid) do
    :erlang.pid_to_list(pid)
    |> to_string()
    |> json_safe_string
  end

  defp any_to_string(ref) when is_reference(ref) do
    '#Ref' ++ rest = :erlang.ref_to_list(ref)

    to_string(rest)
    |> json_safe_string
  end

  defp any_to_string(str) when is_binary(str) do
    json_safe_string(str)
  end

  defp any_to_string(atom) when is_atom(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> rest -> rest
      "nil" -> ""
      binary -> binary
    end
    |> json_safe_string
  end

  defp any_to_string(other) do
    any_to_string(Kernel.inspect(other))
  end

  @doc ~S"""
  Remove any keys not in allowed_keys list
  iex> strip_keys_not_in(%{"this" => 1, "that" => 2}, ["this"])
  %{"this" => 1}
  """
  def strip_keys_not_in(dict, allowed_keys) when is_map(dict) and is_list(allowed_keys) do
    Enum.reduce(Map.keys(dict) -- allowed_keys, dict, fn badkey, acc ->
      Map.delete(acc, badkey)
    end)
  end

  @doc ~S"""
  iex> strip_values_not_is(%{"a" => false, "b" => "not bool"}, &is_boolean/1)
  %{"a" => false}
  """
  def strip_values_not_is(dict, type_test) when is_map(dict) and is_function(type_test) do
    Enum.reduce(Map.keys(dict), dict, fn key, acc ->
      if type_test.(Map.get(acc, key)) do
        acc
      else
        Map.delete(acc, key)
      end
    end)
  end

  @doc ~S"""
  iex> strip_subdict_values_not(%{"sub" => %{"a" => false, "b" => "not bool"}}, "sub", &is_boolean/1)
  %{"sub" => %{"a" => false}}
  """
  def strip_subdict_values_not(dict, key, type_test) do
    Map.put(dict, key, strip_values_not_is(Map.get(dict, key, %{}), type_test))
  end
end
