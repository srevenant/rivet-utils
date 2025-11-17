defmodule Mystery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "mysteries" do
    embeds_one(:enigma, Enigma)
  end

  use Rivet.Utils.Secret, fields: [:enigma]
end
