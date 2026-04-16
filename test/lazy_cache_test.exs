
defmodule Rivet.Utils.LazyCacheTest do
  use ExUnit.Case
  alias Rivet.Utils.Test.TestCache

  defmodule TestCache do
    use Rivet.Utils.LazyCache, expires: 500, wait_prune: 25
  end

  setup do
    start_supervised!(TestCache)
    TestCache.clear()

    on_exit(fn ->
      # avoid cross-test leakage
      if :ets.whereis(TestCache.BUCKET) != :undefined do
        TestCache.clear()
      end
    end)

    :ok
  end

  test "insert/3 and lookup/1 store and return raw ets-style rows" do
    assert true = TestCache.insert(:a, 123)
    assert [{:a, 123, :infinity}] = TestCache.lookup(:a)
    assert [] = TestCache.lookup(:missing)
  end

  test "get/1 returns idiomatic ok tuple or {:error, :not_found}" do
    assert true = TestCache.insert(:a, "value")
    assert {:ok, "value"} = TestCache.get(:a)
    assert {:error, :not_found} = TestCache.get(:missing)
  end

  test "insert/3 rejects invalid keepalive values" do
    assert {:error, _msg} = TestCache.insert(:a, 1, nil)
    assert {:error, _msg} = TestCache.insert(:a, 1, 0)
    assert {:error, _msg} = TestCache.insert(:a, 1, -10)
    assert {:error, _msg} = TestCache.insert(:a, 1, 1.5)
  end

  test "delete/1 removes a key" do
    assert true = TestCache.insert(:a, 1)
    assert true = TestCache.delete(:a)
    assert {:error, :not_found} = TestCache.get(:a)
  end

  test "clear/0 removes all keys" do
    assert true = TestCache.insert(:a, 1)
    assert true = TestCache.insert(:b, 2)

    assert true = TestCache.clear()
    assert 0 == TestCache.size()
  end

  test "get_through/2 returns cached value and does not call fill function" do
    assert true = TestCache.insert(:a, "cached")

    fill = fn _key ->
      flunk("fill function should not be called when cache already contains key")
    end

    assert {:ok, "cached"} = TestCache.get_through(:a, fill)
  end

  test "get_through/2 fills cache on miss and returns fetched value" do
    fill = fn :a -> {:ok, "filled"} end

    assert {:ok, "filled"} = TestCache.get_through(:a, fill)
    assert {:ok, "filled"} = TestCache.get(:a)
  end

  test "get_through/2 propagates fill failure on miss" do
    fill = fn :a -> :bork end

    assert :bork = TestCache.get_through(:a, fill)
    assert {:error, :not_found} = TestCache.get(:a)
  end

  test "finite keepalive entries are pruned by background cleaner" do
    assert true = TestCache.insert(:temp, "value", 10)
    assert {:ok, "value"} = TestCache.get(:temp)

    # give entry time to expire, plus enough time for prune loop to run
    Process.sleep(100)

    assert {:error, :not_found} = TestCache.get(:temp)
  end

  # almost tempted to remove :infinity as a potential value
  test "infinity keepalive entries are not pruned" do
    assert true = TestCache.insert(:perm, "value", :infinity)

    Process.sleep(100)

    assert {:ok, "value"} = TestCache.get(:perm)
  end
end
