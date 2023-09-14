defmodule Rivet.Utils.Errors do
  @moduledoc """
  Helper module for working with ok/error tuples
  """

  alias Ecto.Changeset
  require Logger

  def convert_error_changeset(x) do
    format_changeset(x)
  rescue
    err ->
      Exception.format(:error, err, __STACKTRACE__)
  end

  @spec format_changeset(result :: term | {:error, Changeset.t()} | Changeset.t()) ::
          term | {:error, String.t()} | String.t()
  def format_changeset({:error, %Changeset{} = changeset}) do
    {:error, format_changeset(changeset)}
  end

  def format_changeset(%Changeset{} = changeset) do
    Enum.join(errors_to_list(changeset), ", ")
  end

  def format_changeset(other), do: other

  @spec errors_to_list(Changeset.t()) :: list(String.t())
  def errors_to_list(%Changeset{} = changeset) do
    changeset_errors_to_map(changeset)
    |> flatten_errors([], [])
  end

  @spec changeset_errors_to_map(Changeset.t()) :: map()
  def changeset_errors_to_map(changeset) do
    Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", Rivet.Utils.UniformLogFormat.data2txt(value))
      end)
    end)
  end

  defp flatten_errors(errs, prefix, out) when is_map(errs) do
    flatten_errors(Enum.map(errs, fn {k, v} -> {k, v} end), prefix, out)
  end

  defp flatten_errors([elem | rest], prefix, out) when is_map(elem) do
    flatten_errors(rest, prefix, flatten_errors(elem, prefix, out))
  end

  defp flatten_errors([msg | rest], prefix, out) when is_binary(msg) do
    flatten_errors(rest, prefix, ["#{Enum.join(Enum.reverse(prefix), ".")} #{msg}" | out])
  end

  defp flatten_errors([{k, v} | rest], prefix, out) when is_map(v) do
    flatten_errors(rest, prefix, flatten_errors(v, ["#{k}" | prefix], out))
  end

  defp flatten_errors([{k, v} | rest], prefix, out) when is_list(v) do
    flatten_errors(rest, prefix, flatten_errors(v, ["#{k}" | prefix], out))
  end

  defp flatten_errors([], _, out), do: out

  def log_error({:ok, _} = pass, _src), do: pass

  def log_error({:error, %Ecto.Changeset{} = chgset}, src),
    do: log_error(convert_error_changeset(chgset), src) |> IO.inspect()

  def log_error({:error, error} = pass, src) do
    Logger.warn(error, src: src)
    pass
  end
end
