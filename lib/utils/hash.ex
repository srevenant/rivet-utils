defmodule Rivet.Utils.Hash do
  @moduledoc """
  Helper module for password hashes
  """

  @doc """
  Create a new password hash
  """
  def password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  @doc """
  Verify a password hash
  """
  def verify(password, hash) do
    Bcrypt.verify_pass(password, hash)
  end
end
