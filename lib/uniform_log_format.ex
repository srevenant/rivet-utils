defmodule Rivet.Utils.UniformLogFormat do
  @moduledoc """
  Provide custom log formatting that is friendly for both reading and indexing
  either via ELK or splunk.

  https://surfingthe.cloud/uniform-log-format/

  Contributor: Brandon Gillespie
  """
  alias Logger.Formatter
  import Rivet.Utils.Redact

  @spec format(
          level :: Logger.level(),
          message :: Logger.message(),
          timestamp :: Formatter.time(),
          metadata :: Keyword.t()
        ) :: IO.chardata()
  def format(level, msg, timestamp, meta) do
    meta = [{:level, level} | meta]
    io_msg = format_msg(msg, meta)
    io_meta = format_meta(meta, level)

    [format_date(timestamp), separated(io_msg, io_meta), done()]
  end

  ##############################################################################
  defp format_date({date, time}),
    do: [Formatter.format_date(date), space(), Formatter.format_time(time)]

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  @doc """
  iex> format_meta([a: 1, line: 10, b: 2, level: :info, c: 3], :info) |> IO.iodata_to_binary()
  " a=1 b=2 c=3"
  iex> format_meta([key: 10, line: 20, level: :debug], :info) |> IO.iodata_to_binary()
  " key=10 level=debug"
  iex> format_meta([module: Module.Thing], :debug) |> IO.iodata_to_binary()
  " module=Module.Thing"
  iex> format_meta([module: Module.Thing], :info)
  []
  iex> format_meta([key: 42, module: :phoenix], :info) |> IO.iodata_to_binary()
  " key=42"
  iex> format_meta([key: 42, file: "narf"], :info) |> IO.iodata_to_binary()
  " key=42"
  iex> format_meta([key: 42, file: "narf"], :debug)
  [
   [' ', "key", 61, "42"],
   [' ', "file", 61, "narf"]
  ]
  """
  def format_meta(meta, level), do: filter_meta([], meta, level) |> Enum.reverse()

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  @doc """
  iex> format_msg([], %{})
  []

  Dicts end up being alphabetic keys due to their nature:

  iex> format_msg(%{key: 10, other: 20, a: 5}, %{}) |> IO.iodata_to_binary()
  " other=20 a=5 key=10"

  Keyword lists will stay in-order:

  iex> format_msg([key: 10, a: 5, other: 20], %{}) |> IO.iodata_to_binary()
  " key=10 a=5 other=20"
  iex> format_msg('a charlist', %{})
  [' ', "a charlist"]
  iex> format_msg("a string", %{})
  [' ', "a string"]
  iex> format_msg({:tuple}, %{})
  [' ', "data=", "{:tuple}"]

  #iex> format_msg({:tuple}, %{report_cb: fn x -> inspect(x) end})
  #[' ', "{:tuple}"]
  """
  def format_msg([], _), do: []

  def format_msg(m, _) when is_map(m),
    do: Map.to_list(m) |> to_keyvals([]) |> Enum.reverse()

  def format_msg([x | _] = kw, _) when is_tuple(x),
    do: to_keyvals(kw, []) |> Enum.reverse()

  def format_msg([x | _] = chars, _) when is_number(x) do
    case maybe_charlist_to_string(chars) do
      "" -> []
      "\"\"" -> []
      pass -> [space(), pass]
    end
  end

  def format_msg([x | _] = msg, _) when is_binary(x), do: [space(), msg]

  def format_msg("", _), do: []
  def format_msg(msg, _) when is_binary(msg), do: [space(), msg]

  # gen_statem callback was barfing, just ignore the cb's for now
  # def format_msg(other, %{report_cb: func}) when is_function(func) do
  #    [space(), func.(other, %{})]
  # end

  def format_msg(other, _), do: [space(), "data=", data2txt(other)]

  ##############################################################################
  defp space do
    [?\s]
  end

  defp separated([], []), do: []
  defp separated([], y), do: [?\s, ?-, y]
  defp separated(x, []), do: x
  defp separated(x, y), do: [x, ?\s, ?-, y]

  defp done do
    [?\n]
  end

  ##############################################################################
  # Opinionated filtering of what metadata is shown
  @more_meta [:error, :debug]

  defp filter_meta_key(result, {:function, _}, _), do: result
  defp filter_meta_key(result, {:line, _}, _), do: result
  defp filter_meta_key(result, {:report_cb, _}, _), do: result
  defp filter_meta_key(result, {:pid, _}, l) when l not in @more_meta, do: result
  defp filter_meta_key(result, {:gl, _}, l) when l not in @more_meta, do: result
  defp filter_meta_key(result, {:time, _}, _), do: result
  defp filter_meta_key(result, {:mfa, _}, _), do: result
  defp filter_meta_key(result, {:domain, _}, _), do: result
  defp filter_meta_key(result, {:level, :info}, _), do: result
  defp filter_meta_key(result, {:error_logger, _}, _), do: result
  defp filter_meta_key(result, {:erl_level, _}, _), do: result
  defp filter_meta_key(result, {:application, _}, _), do: result

  @ignore_modules [:phoenix, :plug, :web, :supervisor, Phoenix.Endpoint.Supervisor]
  defp filter_meta_key(result, {:module, v}, _) when v in @ignore_modules, do: result

  defp filter_meta_key(result, {:module, _}, l) when l not in @more_meta, do: result

  @ignore_file [:info, :warn, :error]
  defp filter_meta_key(result, {:file, _}, level) when level in @ignore_file,
    do: result

  defp filter_meta_key(result, {k, v}, _),
    do: to_keyval_string(result, {k, v})

  ##############################################################################
  def filter_meta(result, [kv | rest], level),
    do: filter_meta_key(result, kv, level) |> filter_meta(rest, level)

  # |> Enum.reverse()
  def filter_meta(result, [], _), do: result

  ##############################################################################
  defp to_keyval_string(out, {_, ""}), do: out
  defp to_keyval_string(out, {k, v}), do: [[space(), to_string(k), ?=, data2txt(v)] | out]

  defp to_keyvals([kv | rest], out),
    do: to_keyvals(rest, to_keyval_string(out, kv))

  defp to_keyvals([], out), do: out

  ##############################################################################
  def data2txt(str) when is_binary(str) do
    if String.contains?(str, " ") or String.contains?(str, "\"") do
      inspect(str)
    else
      str
    end
  end

  def data2txt([x | _] = charlist) when is_number(x),
    do: maybe_charlist_to_string(charlist)

  def data2txt(atom) when is_atom(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> rest -> rest
      "nil" -> ""
      binary -> binary
    end
  end

  # only redact raw data dumps for possible leaks
  def data2txt(other), do: inspect(other) |> redact_string()

  ##############################################################################
  defp maybe_charlist_to_string(charlist) do
    try do
      to_string(charlist)
    rescue
      _ ->
        inspect(charlist)
    end
  end
end
