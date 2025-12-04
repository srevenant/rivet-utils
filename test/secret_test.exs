defmodule Rivet.Utils.SecretTest do
  use ExUnit.Case, async: true

  alias Rivet.Utils.Secret

  test "no encryption" do
    data = "foobar"

    assert {:ok, "foobar"} == Secret.encrypt(:none, data)
    assert {:ok, "foobar"} == Secret.decrypt(:none, data)
  end

  test "errors" do
    assert {:error, :unknown_encryption_type} == Secret.encrypt(:bad, "foobar")
    assert {:error, :unknown_encryption_type} == Secret.decrypt(:bogus, <<8, 6, 7, 5, 30, 9>>)
  end

  test "encryption options" do
    %{public: pub, secret: sec} = Zodium.box_keypair()
    dec_opts = %{public_key: pub, secret_key: sec}
    enc_opts = %{public_key: pub}

    assert {:ok, enc} = Secret.encrypt(:nacl, "Super secret password", enc_opts)
    assert {:ok, "Super secret password"} == Secret.decrypt(:nacl, enc, dec_opts)

    Application.put_env(:core, :encryption_keys, Map.new(dec_opts, fn {k, v} -> {k, Base.encode64(v)} end))
    assert {:ok, "Super secret password"} == Secret.decrypt(:nacl, enc)

    Application.delete_env(:core, :encryption_keys)
  end

  test "armoring" do
    assert Secret.armor(nil) |> is_nil()
    assert Secret.dearmor(nil) |> is_nil()

    assert "ZH2Wr8g=" == Secret.armor(<<100, 125, 150, 175, 200>>)
    assert {:ok, <<100, 125, 150, 175, 200>>} == Secret.dearmor("ZH2Wr8g=")
  end

    test "__using__ args" do
    # It's shocking this works.
    defmodule NotSecret do
      use Ecto.Schema
      import Ecto.Changeset

      schema "not_real" do
      end

      # Covers the default values of `:type` and `:fields`.
      use Rivet.Utils.Secret
    end
  end
end
