defmodule Rivet.Utils.Test.JsonConfigProvider do
  use ExUnit.Case
  doctest Rivet.Utils.JsonConfigProvider, import: true

  @testfile "./__json_test_config_.json"
  @testdata """
  {"web":{"tardis":"blue", "Elixir.Rivet.Utils.JsonConfigProvider": {"sub": "key"}}}
  """
  def cleanup() do
    File.rm!(@testfile)
  end

  describe "JsonConfigProvider" do
    setup do
      on_exit(&cleanup/0)
    end

    test "config provider" do
      assert Application.get_env(:web, :tardis) == nil
      assert File.write!(@testfile, @testdata) == :ok
      assert Rivet.Utils.JsonConfigProvider.init(@testfile) == @testfile
      updates = Rivet.Utils.JsonConfigProvider.load([], @testfile)
      assert updates == [web: [{Rivet.Utils.JsonConfigProvider, [sub: "key"]}, {:tardis, "blue"}]]
      Application.put_all_env(updates)
      assert Application.get_env(:web, :tardis) == "blue"
      assert Application.get_env(:web, Rivet.Utils.JsonConfigProvider) == [{:sub, "key"}]
    end
  end
end
