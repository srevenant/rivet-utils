defmodule Rivet.Utils.Secret do
  @moduledoc """
  Stores encrypted secrets in the database.

  The `type` field is a free-form string and should contain the
  encryption algorithm and some kind of indication of where to
  find the key to encrypt and decrypt each field in `fields`.

  The struct is expected to keep each encrypted secret in a field
  with the "_secret" suffix as `:binary`, and it will be
  decrypted into the virtual field with no suffix.

  Usage example:

  ```
  typed_schema "credentials" do
    field(:kind, :string)
    field(:username_secret, :binary)
    field(:username, :string, virtual: true)
    field(:password_secret, :binary)
    field(:password, :string, virtual: true)

    timestamps()
  end

  use Rivet.Ecto.Collection,
    update: [:kind, :username, :password]

  use Rivet.Utils.Secret, type: :nacl, fields: [:username, :password]
  ```

  This creates `validate_post/1`, which encrypts
  """
  @type secret_type :: :none | :nacl

  defmacro __using__(opts) do
    type = opts[:type] || :nacl
    fields = opts[:fields] || []

    quote location: :keep do
      # Encrypts `data` according to `type` before saving, even if neither changed,
      # as this may be a re-key operation based on information in
      # Application.get_env, etc. If the encrypted data doesn't actually change,
      # Ecto won't update it in the database.
      def validate_post(chgset) do
        type = unquote(type)
        fields = unquote(fields)

        Enum.reduce(fields, chgset, fn field, chgset ->
          secret_field = String.to_atom("#{field}_secret")

          # Assocs and embeds don't have a secret field on the parent, so
          # skip encrypting in that case.
          with {_, _} <- fetch_field(chgset, secret_field),
               {:ok, data} <- fetch_change(chgset, field),
               {:ok, enc} <- Rivet.Utils.Secret.encrypt(type, data) do
            data = Rivet.Utils.Secret.and_armor?(chgset, enc)
            put_change(chgset, secret_field, data)
          else
            :error ->
              # Field isn't set, don't encrypt.
              chgset

            {:error, :bad_key} ->
              add_error(chgset, field, "Could not encrypt data", encryption_type: type)
          end
        end)
      end

      def unseal(%__MODULE__{} = item, fields \\ unquote(fields)) do
        type = unquote(type)

        Enum.reduce(fields, item, fn field, item ->
          case Map.fetch(item, field) do
            {:ok, %mod{} = assoc} ->
              %{item | field => mod.unseal(assoc)}

            _ ->
              secret_field = String.to_atom("#{field}_secret")

              with {:ok, encrypted} <- Map.fetch(item, secret_field),
                   {:ok, enc} <- Rivet.Utils.Secret.should_dearmor?(item, encrypted),
                   {:ok, plain} <- Rivet.Utils.Secret.decrypt(type, enc) do
                Map.put(item, field, plain)
              else
                _ ->
                  item
              end
          end
        end)
      end
    end
  end

  @spec encrypt(secret_type(), binary(), map()) :: {:ok, binary()} | {:error, term()}
  def encrypt(type, data, opts \\ %{})

  def encrypt(:none, data, _) do
    {:ok, data}
  end

  def encrypt(:nacl, plain, opts) do
    with %{public_key: pk} <- nacl_encryption_keys(opts) do
      {:ok, :enacl.box_seal(plain, pk)}
    else
      _ ->
        {:error, :bad_key}
    end
  end

  def encrypt(_, _, _), do: {:error, :unknown_encryption_type}

  @spec decrypt(secret_type(), binary(), map()) :: {:ok, binary()} | {:error, term()}
  def decrypt(type, data, opts \\ %{})

  def decrypt(:none, data, _) do
    {:ok, data}
  end

  def decrypt(:nacl, ciphered, opts) do
    with %{public_key: pk, secret_key: sk} <- nacl_encryption_keys(opts) do
      :enacl.box_seal_open(ciphered, pk, sk)
    else
      _ ->
        {:error, :bad_key}
    end
  end

  def decrypt(_, _, _), do: {:error, :unknown_encryption_type}

  defp nacl_encryption_keys(%{public_key: pk, secret_key: sk}) do
    %{public_key: pk, secret_key: sk}
  end

  defp nacl_encryption_keys(%{public_key: pk}) do
    %{public_key: pk}
  end

  defp nacl_encryption_keys(_) do
    Application.get_env(:core, :encryption_keys, %{})
    |> Map.take([:public_key, :secret_key])
    |> Map.new(fn {k, val} -> {k, Base.decode64!(val)} end)
  end

  def armor(nil), do: nil

  def armor(data) do
    Base.encode64(data)
  end

  def dearmor(nil), do: nil

  def dearmor(ascii) do
    Base.decode64(ascii)
  end

  @doc """
  Conditionally armors the encrypted secret as ASCII when stored in an
  embedded schema. Embedded schema do not have a metadata field, while
  regular table-backed schema do. Embedded schema are typically stored as
  JSON, which does not deal well with raw bytes.
  """
  def and_armor?(%{data: %{__meta__: _}}, raw_secret) do
    raw_secret
  end

  def and_armor?(_, raw_secret) do
    armor(raw_secret)
  end

  def should_dearmor?(%{__meta__: _}, encrypted) do
    {:ok, encrypted}
  end

  def should_dearmor?(_, encrypted) do
    dearmor(encrypted)
  end
end
