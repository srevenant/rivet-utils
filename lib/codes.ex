defmodule Rivet.Utils.Codes do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  @doc """
  iex> uuid = stripped_uuid()
  iex> String.length(uuid)
  31
  """
  def stripped_uuid do
    Ecto.UUID.generate() |> stripped_uuid
  end

  def stripped_uuid(uuid) do
    clean = cleaned_short_id(uuid)

    # remove the uuidv4 version#
    String.slice(clean, 0, 12) <> String.slice(clean, 13, 19)
  end

  @doc """
  iex> cleaned_short_id("asdf-L0Ol")
  "asdf1001"
  """
  def cleaned_short_id(uuid) do
    uuid
    |> String.replace("-", "")
    |> String.downcase()
    |> String.replace("o", "0")
    |> String.replace("l", "1")
  end

  @doc """
  iex> {:ok, code} = generate(5, fn _ -> false end)
  iex> String.length(code)
  5
  """
  def generate(len, exists) do
    code = stripped_uuid() |> String.slice(0, len)

    case exists.(code) do
      {:ok, _} ->
        generate(len, exists)

      _ ->
        {:ok, code}
    end
  end

  def get_shortest(biggest, len, increment, exists) do
    short_id = biggest |> String.slice(0, len)

    case exists.(short_id) do
      {:ok, _} ->
        get_shortest(biggest, len + increment, increment, exists)

      _ ->
        {:ok, short_id}
    end
  end
end
