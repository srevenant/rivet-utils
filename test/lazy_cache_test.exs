defmodule Rivet.Utils.Test.TestCache do
  use Rivet.Utils.LazyCache, bucket_key: :test_bucket
end

defmodule Rivet.Utils.LazyCacheTest do
  use ExUnit.Case
  alias Rivet.Utils.Test.TestCache

  setup_all do
    {:ok, _} = start_supervised(TestCache, restart: :temporary)
    %{}
  end

  def keep_alive_error() do
    "Keep Alive Time is not valid. Should be a positive Integer or :keep_alive_forever."
  end

  test "should insert element in cache" do
    assert TestCache.insert("key", "value", 1000) == true
  end

  test "should increment cache size when insert" do
    TestCache.purge_cache()
    TestCache.insert("key", "value", 1000)
    assert TestCache.size() == 1
  end

  test "keep alive should be an Integer" do
    insert = TestCache.insert("key", "value", "1000")
    assert insert == {:error, keep_alive_error()}
  end

  test "keep alive should be positive" do
    insert = TestCache.insert("key", "value", 0)
    assert insert == {:error, keep_alive_error()}
  end

  test "keep alive cannot be nil" do
    insert = TestCache.insert("key", "value", nil)
    assert insert == {:error, keep_alive_error()}
  end

  test "keep alive cannot be negative" do
    insert = TestCache.insert("key", "value", -1)
    assert insert == {:error, keep_alive_error()}
  end

  test "should delete element from cache" do
    TestCache.insert("key", "value", 1000)
    TestCache.delete("key")
    assert TestCache.size() == 0
  end

  test "data exists when inserted" do
    TestCache.insert("key", "value", 1000)
    assert [{"key", "value", _}] = TestCache.lookup("key")
  end

  test "data cannot be looked up when deleted" do
    TestCache.insert("key", "value", 1000)
    TestCache.delete("key")
    assert TestCache.lookup("key") == []
  end

  test "data is cleared correctly" do
    TestCache.insert("key", "value", 1000)
    TestCache.clear()
    assert TestCache.lookup("key") == []
  end

  test "if there is data, cache is correctly cleared" do
    TestCache.insert("key", "value", 1000)
    assert TestCache.clear() == true
  end

  test "data is not purged before its time" do
    TestCache.insert("key", "value", 100_000)
    TestCache.purge_cache()
    assert [{"key", "value", ttl}] = TestCache.lookup("key")
    assert is_number(ttl) && ttl > 0
  end

  test "data can be stored forever" do
    TestCache.insert("key", "value")
    TestCache.purge_cache()
    [data] = TestCache.lookup("key")
    assert elem(data, 2) == :keep_alive_forever
  end
end
