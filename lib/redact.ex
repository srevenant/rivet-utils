defmodule Rivet.Utils.Redact do
  @moduledoc """
  redact text based on common patterns for insecure data

  Contributor: Unknown
  """

  ##############################################################################
  @password_rx ~r/((password|key)\s*([=:]))\s*(<<[,\s\.0-9]+>>|"?([^\s]+)?"?)/i
  defp redact_password(msg),
    do: Regex.replace(@password_rx, msg, fn _, _, key, eq -> "#{key}#{eq}***" end, global: true)

  @spec redact_string(message :: String.t()) :: String.t()
  @doc """
  iex> redact_string("this password:Frieb398f3e is nice")
  "this password:*** is nice"
  iex> redact_string("this password:\\"Frieb398f3e\\" is nice")
  "this password:*** is nice"
  iex> redact_string("this password=Frieb398f3e is nice")
  "this password=*** is nice"
  iex> redact_string("this password=\\"Frieb398f3e\\" is nice")
  "this password=*** is nice"
  iex> redact_string("this password: Frieb398f3e is nice")
  "this password:*** is nice"
  iex> redact_string("this password: \\"Frieb398f3e\\" is nice")
  "this password:*** is nice"
  iex> redact_string("this password = Frieb398f3e is nice")
  "this password=*** is nice"
  iex> redact_string("this password = \\"Frieb398f3e\\" is nice")
  "this password=*** is nice"
  iex> redact_string("this key: <<10, 20, 30>> is nice")
  "this key:*** is nice"
  iex> redact_string("curve_publickey: <<142, 243, 120, 122, ...>>, curve_secretkey: <<97, 10, 116, 57, 7, 84, 65, 254, 83, 106>>,")
  "curve_publickey:***, curve_secretkey:***,"
  """
  def redact_string(string) do
    # could add more in future...
    redact_password(string)
  end
end
