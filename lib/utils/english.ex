defmodule Rivet.Utils.English do
  @moduledoc """
  Various english-centric human wording helper functions.
  """

  @doc """
  iex> titleize("mote in god's eye")
  "Mote in God's Eye"
  """
  @skip ~w(a an the of in on and)

  def titleize(str) do
    str
    |> String.split()
    |> Enum.with_index()
    |> Enum.map(fn {word, i} ->
      if i > 0 and String.downcase(word) in @skip do
        String.downcase(word)
      else
        String.capitalize(word)
      end
    end)
    |> Enum.join(" ")
  end

  # helper so you can just import one module and also get this
  defdelegate capitalize(x), to: String

  @doc """
  iex> a_or_an("explosion")
  "an explosion"
  iex> a_or_an("cart")
  "a cart"
  """
  @vowels MapSet.new([?a, ?e, ?i, ?o, ?u])
  def a_or_an(<<first::utf8, _rest::binary>> = str) do
    if MapSet.member?(@vowels, first) do
      "an " <> str
    else
      "a " <> str
    end
  end

  def is_or_are(count) when count > 1, do: "are"
  def is_or_are(1), do: "is"

  @doc """
  iex> pluralize(1, "cave")
  "cave"
  iex> pluralize(3, "cave")
  "caves"
  """
  def pluralize(count, word) when count > 1, do: Inflex.pluralize(word)
  def pluralize(_, word), do: word

  @doc """
  chicago_number as in the Chicago Style Guide's rule for numbers which is to
  spell out numbers lower than 100.

  We could use `Number.to_word()` except that library has heavy dependencies
  which are not necessary here.

  iex> chicago_number(1)
  "one"
  iex> chicago_number(42)
  "forty-two"
  iex> chicago_number(120)
  "120"

  """
  @ones ~w(zero one two three four five six seven eight nine ten
           eleven twelve thirteen fourteen fifteen sixteen seventeen
           eighteen nineteen)

  @tens ~w(zero ten twenty thirty forty fifty sixty seventy eighty ninety)
  def chicago_number(n) when n in 0..19, do: Enum.at(@ones, n)

  def chicago_number(n) when n in 20..99 do
    tens = Enum.at(@tens, div(n, 10))
    ones = rem(n, 10)

    if ones == 0 do
      tens
    else
      "#{tens}-#{Enum.at(@ones, ones)}"
    end
  end

  def chicago_number(n), do: comma_number(n)

  @doc """
  Similarly, just trying to avoid heavy dependencies, do this here.

  iex> comma_number(-1_234_567)
  "-1,234,567"
  iex> comma_number(1_234.50000000000353)
  "1,234.5"
  iex> comma_number(-1_234.5000)
  "-1,234.5"
  iex> comma_number(134.0)
  "134"
  """
  def comma_number(n) do
    {int, dec} =
      case number_to_string(n) |> String.split(".", parts: 2) do
        [int] -> {int, ""}
        [int, dec] -> {int, String.trim_trailing(dec, "0")}
      end

    int = String.replace(int, ~r/\B(?=(?:\d{3})+(?!\d))/, ",")

    if dec == "" do
      int
    else
      "#{int}.#{dec}"
    end
  end

  def number_to_string(n) when is_integer(n), do: Integer.to_string(n)
  def number_to_string(n) when is_float(n), do: :erlang.float_to_binary(n, decimals: 10)
end
