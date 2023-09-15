defmodule Rivet.Utils.Puid do
  @moduledoc """
  Puid.generate/0 is included with the `use` statement below.  It generates 18 random characters.
  """
  use Puid, total: 10.0e6, risk: 1.0e12, chars: :safe32
end

defmodule Rivet.Utils.RandChars do
  @doc """
  random/0 generates a 72-character random string.
  """
  def random() do
    Enum.map_join(1..4, "", fn _ -> Rivet.Utils.Puid.generate() end)
  end
end
