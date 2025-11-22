defmodule Rivet.Utils.JsonConfigProvider do
  @moduledoc """
  Derived from toml-elixir/Toml.Provider https://github.com/bitwalker/toml-elixir/blob/master/lib/provider.ex
  and https://hexdocs.pm/elixir/Config.Provider.html#module-sample-config-provider

  This is a runtime config provider (for 12factor apps).

  It will merge json data into the config structure.

  In Elixir Config:
  config :app, That.Module,
    the: thing

  In Elixir (Raw)

  Application.get_env(:app, That.Module)
  [{ the: "thing" }]

  In JSON, you have two special syntaxes to the keys:

  1. prefix 'Elixir.' on the module name if it's an elixir module:

    {"app": {"Elixir.That.Module": {"the": "thing"}}}

  2. use "$NAME:name" as the key and it will pull that value at runtime
     from the OS environment[NAME], saving it as [name] in the current
     heirarchial location of the config file, defaulting the value to
     whatever is set in the static variable instead.

  Contributor: Brandon Gillespie
  """
  require Logger

  @behaviour Config.Provider

  def init(p), do: p

  def load(config, default_path) do
    {:ok, _} = Application.ensure_all_started(:jason)

    path =
      case System.fetch_env("CONFIG_PATH") do
        :error -> default_path
        {:ok, path} -> path
      end

    Logger.info("Loading runtime config", file: path)

    with {:ok, expanded} <- expand_path(path),
         {:ok, _} <- check_file_path(expanded),
         {:ok, body} <- File.read(expanded),
         {:ok, cfg} <- Jason.decode(body),
         keyword when is_list(keyword) <- to_keyword(cfg) do
      Config.Reader.merge(config, keyword)
    else
      {:error, :enoent} ->
        exit({:shutdown, "File read failed"})

      {:error, reason} ->
        exit({:shutdown, "Unable to load config.json", reason})
    end
  end

  defp check_file_path(file_path) do
    if File.exists?(file_path) do
      {:ok, true}
    else
      {:error, "Invalid file: #{inspect(file_path)}"}
    end
  end

  @doc false
  def get([app | keypath]) do
    config = Application.get_all_env(app)

    case get_in(config, keypath) do
      nil ->
        nil

      val ->
        {:ok, val}
    end
  end

  # At the top level, convert the map to a keyword list of keyword lists
  # Keys with no children (i.e. keys which are not tables) are dropped
  defp to_keyword(map) when is_map(map) do
    for {k, v} <- map, v2 = to_keyword2(v), is_list(v2), into: [] do
      keyword_pair(k, v2)
    end
  end

  # For all other values, convert tables to keywords
  defp to_keyword2(map) when is_map(map) do
    for {k, v} <- map, v2 = to_keyword2(v), into: [] do
      keyword_pair(k, v2)
    end
  end

  # And leave all other values untouched
  defp to_keyword2(term), do: term

  ##############################################################################
  # On exit handler throws error that it can't remove the json file; for now
  # leave commented out unless we need to make a change.
  @doc """
  ```
  iex> keyword_pair("doctor", "who")
  {:doctor, "who"}
  iex> keyword_pair("$DOCTOR:doctor", "who")
  {:doctor, "who"}
  iex> keyword_pair("$DOCTOR_TEST_ENV", "who")
  {:DOCTOR_TEST_ENV, "who"}
  iex> System.put_env("DOCTOR_TEST_ENV", "WHO")
  iex> keyword_pair("$DOCTOR_TEST_ENV:doctor", "who")
  {:doctor, "WHO"}
  iex> keyword_pair("${DOCTOR_TEST_ENV}", "who")
  {:DOCTOR_TEST_ENV, "WHO"}
  iex> keyword_pair("${DOCTOR_TEST_ENV", "WHO")
  ** (RuntimeError) Invalid environment key `${DOCTOR_TEST_ENV`
  ```
  """
  def keyword_pair("${" <> key_name, v_default) do
    case String.at(key_name, -1) do
      "}" ->
        String.slice(key_name, 0..-2//1)

      _ ->
        raise "Invalid environment key `${#{key_name}`"
    end
    |> inline_environ_var(v_default)
  end

  def keyword_pair("$" <> kn, v_default), do: inline_environ_var(kn, v_default)

  def keyword_pair(k, v) do
    {String.to_atom(k), v}
  end

  defp inline_environ_var(key_name, v_default) do
    [key, name] =
      case String.split(key_name, ":") do
        [key] -> [key, key]
        pass -> pass
      end

    name = String.to_atom(name)

    case System.get_env(key) do
      nil -> {name, v_default}
      value -> {name, value}
    end
  end

  ##############################################################################
  def expand_path(path) when is_binary(path) do
    case expand_path(path, <<>>) do
      {:ok, p} ->
        {:ok, Path.expand(p)}

      {:error, _} = err ->
        err
    end
  end

  defp expand_path(<<>>, acc),
    do: {:ok, acc}

  defp expand_path(<<?$, ?\{, rest::binary>>, acc) do
    case expand_var(rest) do
      {:ok, var, rest} ->
        expand_path(rest, acc <> var)

      {:error, _} = err ->
        err
    end
  end

  defp expand_path(<<c::utf8, rest::binary>>, acc) do
    expand_path(rest, <<acc::binary, c::utf8>>)
  end

  defp expand_var(bin),
    do: expand_var(bin, <<>>)

  defp expand_var(<<>>, _acc),
    do: {:error, :unclosed_var_expansion}

  defp expand_var(<<?\}, rest::binary>>, acc),
    do: {:ok, System.get_env(acc) || "", rest}

  defp expand_var(<<c::utf8, rest::binary>>, acc) do
    expand_var(rest, <<acc::binary, c::utf8>>)
  end
end
