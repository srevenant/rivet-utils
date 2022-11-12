defmodule Rivet.Utils.Enum do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  @doc """
  like Enum.find_value() on a list of [{rx, fn}, ..], calling fn on the matched
  rx and returning the result.  Almost like a case statement (see to_minutes below)

  iex> opts = [
  ...>   {~r/^(\\d+)\\s*(m|min(s)?|minute(s)?)$/, fn match, _ -> {:min, match} end},
  ...>   {~r/^(\\d+)\\s*(h|hour(s)?|hr(s)?)$/, fn match, _ -> {:hr, match} end},
  ...> ]
  ...> enum_rx(opts, "30 m")
  {:min, ["30 m", "30", "m"]}
  iex> enum_rx(opts, "1.5 hr") # doesn't match because of the period
  nil
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
  sequence helps you know if any item in a list of tuples failed

  iex> vals = [ok: 1, ok: 2, ok: 3]
  ...> sequence(vals)
  {:ok, [1,2,3]}
  iex> vals = [ok: 1, error: "nan", ok: 3]
  ...> sequence(vals)
  {:error, "nan"}
  """
  @spec sequence(list(keyword())) :: {:error, any()} | {:ok, list(any())}
  def sequence(keywords) do
    keywords
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, fn
      _, {:error, err} -> {:error, err}
      {:error, err}, _ -> {:error, err}
      {:ok, val}, {:ok, vals} -> {:ok, [val | vals]}
    end)
  end
end
