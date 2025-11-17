defmodule Enigma do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:hidden_secret, :string)
    field(:hidden, :string, virtual: true)
  end

  use Rivet.Utils.Secret, fields: [:hidden]
end
