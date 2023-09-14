defmodule Rivet.Utils.Map do
  @moduledoc """
  Helper module for Maps

  Contributors: Brandon Gillespie, Mark Erickson, Lyle Mantooth
  """

  import Transmogrify.As

  @doc """
  Recursively walk a keyword list, converting it to a map

  iex> [a: 1] |> as_map
  %{a: 1}
  iex> %{a: 1} |> as_map
  %{a: 1}
  iex> [a: ["list"]] |> as_map
  %{a: ["list"]}
  iex> [key1: 10, key2: [three: 3], key3: %{a: 1, b: 2}] |> as_map
  %{key1: 10, key2: %{three: 3}, key3: %{a: 1, b: 2}}
  iex> [cxs_apps: [supervisor: [secrets: ["abc"], index: "0"]]] |> as_map
  %{cxs_apps: %{supervisor: %{index: "0", secrets: ["abc"]}}}
  """
  def as_map(list) when is_list(list) do
    if Keyword.keyword?(list) do
      Map.new(list, fn {k, v} ->
        {as_atom(k), as_map(v)}
      end)
    else
      list
    end
  end

  def as_map(v), do: v

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

  ################################################################################

  @doc """

  iex> map_to_kvstr(%{a: "b", c: "10", d: "longer with space"})
  "c=10 a=b d=\\"longer with space\\""
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
