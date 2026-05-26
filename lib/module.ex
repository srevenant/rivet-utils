defmodule Rivet.Utils.Module do
  alias Transmogrify.Snakecase
  import String

  @doc """
  iex> :module_id = mod_to_id_key(Core.Tools.Module)
  iex> :module_id = mod_to_idname(Core.Tools.Module)
  """
  def mod_to_id_key(mod), do: mod_to_name_string(mod) |> id_key()

  # so the deprecated path still works; this should compile out
  defdelegate mod_to_idname(mod), to: __MODULE__, as: :mod_to_id_key

  @doc """
  Note: "name" in name string implies snake, not module/pascal case

  iex> :narf = mod_to_name(Core.Tools.Narf)
  iex> "narf" = mod_to_name(Core.Tools.Narf, :string)
  """
  def mod_to_name(mod, output \\ :atom)

  def mod_to_name(mod, :atom), do: mod_to_name_string(mod) |> to_atom()
  def mod_to_name(mod, :string), do: mod_to_name_string(mod)

  defp mod_to_name_string(m), do: mod_basename_snake(m)

  @doc """
  iex> ModuleName = mod_basename(Core.Tools.ModuleName)
  iex> ModuleName = mod_basename(Core.Tools.ModuleName, :module)
  iex> "module_name" = mod_basename(Core.Tools.ModuleName, :string)
  iex> :module_name = mod_basename(Core.Tools.ModuleName, :atom)
  """
  def mod_basename(mod, output \\ :module)

  def mod_basename(mod, :module), do: [mod_basename_(mod)] |> Module.concat()
  def mod_basename(mod, :string), do: mod_basename_snake(mod)
  def mod_basename(mod, :atom), do: mod_basename_snake(mod) |> to_atom()

  defp mod_basename_(mod), do: List.last(Module.split(mod))
  defp mod_basename_snake(mod), do: mod_basename_(mod) |> Snakecase.convert()

  @doc """
  iex> Core.Db.IsParent = mod_parent(Core.Db.IsParent.Log)
  iex> Core.Db.IsParent = mod_parent(Core.Db.IsParent.Log, :module)
  iex> ["Core", "Db", "IsParent"] = mod_parent(Core.Db.IsParent.Log, :list)
  """
  def mod_parent(mod, output_case \\ :module)

  def mod_parent(mod, :module), do: mod_parent_module(mod)
  def mod_parent(mod, :list), do: mod_parent_list(mod)

  defp mod_parent_module(mod), do: mod_parent_list(mod) |> Module.concat()
  defp mod_parent_list(mod), do: Module.split(mod) |> Enum.drop(-1)

  @doc """
  iex> :ip_id = id_key(:ips)
  iex> :ip_id = id_key(:ip)
  iex> :ip_id = id_key("ip")
  iex> :ip_id = id_key("long_prefix_ip")
  """
  def id_key(input) when is_atom(input), do: id_key(Atom.to_string(input))

  def id_key(input) when is_binary(input) do
    String.split(input, "_")
    |> List.last()
    |> String.trim_trailing("s")
    |> Kernel.<>("_id")
    |> to_atom()
  end

  @doc """
  iex> :module_id = mod_id_key(Some.Long.Modules)
  """
  def mod_id_key(input), do: mod_basename(input, :atom) |> id_key()
end

