defmodule Rivet.Utils.Dig do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  import Rivet.Utils.Types, only: [as_atom: 1]

  @rx_split ~r/\.(?=[^\]]*(?:\[|$))/
  @rx_index ~r/^(.*)\[{(.*[^\]]*)}\]$/

  @doc """
  [see also: frontend code base for mirror code in js]

  keys must be a list of {direct: true|false, key: y}
  where direct=true is simply obj[key], and indirect does
  a search of an array for the first key/value match

  NOTE: keys are always converted to atoms

  iex> dig_keys("a[{b:name}].capKey.d")
  [
    %{ direct: true, key: :a },
    %{ direct: false, key: [:b, "name"] },
    %{ direct: true, key: :capKey },
    %{ direct: true, key: :d }
  ]
  iex> dig_keys("a[{b:name}].capKey.d", snake_case: true)
  [
    %{ direct: true, key: :a },
    %{ direct: false, key: [:b, "name"] },
    %{ direct: true, key: :cap_key },
    %{ direct: true, key: :d }
  ]
  """
  def dig_keys(key, opts \\ [])

  def dig_keys(key, opts) when is_binary(key) do
    key_to_atom =
      if Keyword.get(opts, :snake_case, false),
        do: &to_atom_snaked/1,
        else: &as_atom/1

    Regex.split(@rx_split, key)
    |> Enum.reduce([], fn e, acc ->
      case Regex.run(@rx_index, e) do
        [_, key, value] ->
          [subkey, subvalue] = Regex.split(~r/\s*:\s*/, value)

          acc ++
            [
              %{direct: true, key: key_to_atom.(key)},
              %{direct: false, key: [key_to_atom.(subkey), subvalue]}
            ]

        _ ->
          acc ++ [%{direct: true, key: key_to_atom.(e)}]
      end
    end)
  end

  def dig_keys(key, _opts) when is_list(key) do
    Enum.map(key, &%{direct: true, key: &1})
  end

  defp to_atom_snaked(val) do
    Transmogrify.snakecase(val) |> as_atom
  end

  @doc """
  dig a value using pre-parsed digKeys
  """
  def digx(dict, key, default \\ nil)

  def digx(dict, [key], default) do
    case digx_getvalue(dict, key) do
      nil ->
        default

      result ->
        result
    end
  end

  def digx(dict, [key | keySet], default) do
    # need better way to pipeline this
    case digx_getvalue(dict, key) do
      value when is_map(value) or is_list(value) ->
        digx(value, keySet, default)

      _ ->
        default
    end
  end

  defp digx_getvalue(dict, %{direct: true, key: key}),
    do: Map.get(dict, key)

  defp digx_getvalue(list, %{direct: false, key: [key, value]}),
    do: Enum.find(list, fn v -> Map.get(v, key) == value end)

  @doc """

  dig a value using a string index digKeys notation
  This takes both a.b.c and a[{index}].b.c, where index
  in the second case is an indirect key/value lookup

  iex> data = %{a: [ %{c: 1}, %{d: 2}, %{b: "name", c: %{d: "meep"}}]}
  iex> dig(data, "a[{b:name}].c.d")
  "meep"
  iex> dig(data, "a[{b:name}].d.d")
  nil
  iex> dig(data, "a[{b:bigglesworth}].c.d")
  nil
  """
  def dig(dict, key, default \\ nil), do: digx(dict, dig_keys(key), default)

  ################################################################################
  ## top level: just put in the value
  def dugx(dict, [%{direct: true, key: key}], value),
    do: {:ok, Map.put(dict, key, value)}

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  ## mid-level direct key
  def dugx(dict, [%{direct: true, key: key} | rest], value) do
    with {:ok, child} <- dugx(Map.get(dict, key, %{}), rest, value) do
      {:ok, Map.put(dict, key, child)}
    end
  end

  ## # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  ## mid-level indirect array match key
  def dugx(list, [%{direct: false, key: [key, match]} | rest], value) when is_list(list) do
    case Enum.find_index(list, fn e -> e[key] == match end) do
      nil ->
        # append
        with {:ok, child} <- dugx(Map.new([{key, match}]), rest, value) do
          {:ok, list ++ [child]}
        end

      x ->
        with {:ok, child} <- dugx(Enum.at(list, x), rest, value) do
          {:ok, List.replace_at(list, x, child)}
        end
    end
  end

  def dugx(_, _, _), do: {:error, "Unsupported key type"}

  ################################################################################
  @doc """
  This is the inverse of dig -- put a value in place

  iex> data = %{a: [ %{c: 1}, %{d: 2}, %{b: "road", c: %{d: "meep"}}]}
  iex> dug(data, "a[{b:road}].c.d", "meep meep")
  {:ok, %{a: [ %{c: 1}, %{d: 2}, %{b: "road", c: %{d: "meep meep"}}]}}
  iex> dug(data, "a[{b:runner}].c.d", "meep meep")
  {:ok, %{a: [%{c: 1}, %{d: 2}, %{b: "road", c: %{d: "meep"}}, %{b: "runner", c: %{d: "meep meep"}}]}}
  iex> dug(%{i: 10}, "i", 5)
  {:ok, %{i: 5}}
  iex> dug(%{a: [%{b: "z"}, %{b: "z"}]}, "a[{b:z}].c", 5)
  {:ok, %{a: [%{b: "z", c: 5}, %{b: "z"}]}}

  """
  def dug(dict, key, default \\ nil), do: dugx(dict, dig_keys(key), default)

  def dug!(dict, key, default \\ nil) do
    with {:ok, result} <- dugx(dict, dig_keys(key), default) do
      result
    end
  end

  # simplified, less functional, more efficient/focused - gives a default value which get_in doesn't
  def dig_in(dict, keys, def_val \\ nil) do
    case get_in(dict, keys) do
      nil -> def_val
      pass -> pass
    end
  end
end
