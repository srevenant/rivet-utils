defmodule Rivet.Utils.Network do
  @moduledoc """
  Helper module for common type handling needs

  Contributors: Brandon Gillespie, Mark Erickson, Lyle Mantooth
  """

  @doc """
  ```elixir
  iex> lookup_address("nope")
  {:error, :nxdomain}
  iex> lookup_address(10)
  {:error, :einval}
  iex> lookup_address(~c"localhost")
  {:ok, {127,0,0,1}}
  iex> lookup_address("localhost")
  {:ok, {127,0,0,1}}
  iex> lookup_address("127.0.0.1")
  {:ok, {127,0,0,1}}
  ```
  """
  @spec lookup_address(String.t() | charlist()) :: {:ok, tuple()} | {:error, term()}
  def lookup_address(address) when is_binary(address),
    do: lookup_address(to_charlist(address))

  def lookup_address(address) when is_list(address) do
    # parse_address/1 returns {:ok, ip} if successful. If there's an error,
    # `address` is probably a hostname.
    with {:error, :einval} <- :inet.parse_address(address),
         {:ok, {:hostent, ^address, _, _, _, [ip | _]}} <- :inet.gethostbyname(address) do
      {:ok, ip}
    end
  end

  def lookup_address(_), do: {:error, :einval}
end
