defmodule Rivet.Utils.LazyCache do
  @moduledoc """
  Originally lazy_cache @ https://hex.pm/packages/lazy_cache; but with updates.
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @bucket String.to_atom("#{__MODULE__}.BUCKET")
      require Logger
      use GenServer
      import Rivet.Utils.Time, only: [epoch_time: 1]

      @doc """
      Start scheduling the works for clearing the cache.
      This method should be called before performing any operation.

      Returns `{:ok, PID}`.
      """
      def start_link(_), do: GenServer.start_link(__MODULE__, %{})

      @doc """
      Store anything for a certain amount of time or forever if no keep alive time specified

      Returns a boolean indicating if element has been correctly inserted.
      """
      @spec insert(any(), any(), number() | atom()) :: boolean() | {:error, String.t()}
      def insert(key, value, keepAliveInMillis \\ :keep_alive_forever) do
        if not check_valid_keep_alive(keepAliveInMillis) do
          {:error,
           "Keep Alive Time is not valid. Should be a positive Integer or :keep_alive_forever."}
        else
          :ets.insert(
            @bucket,
            {key, value, get_keepalive(keepAliveInMillis)}
          )
        end
      end

      @doc """
      Retrieve anything by its key.

      Returns `[{your_stored_tuple}]`.
      """
      def lookup(key) do
        :ets.lookup(@bucket, key)
      rescue
        err ->
          Logger.warning("Cache lookup error #{inspect(@bucket)} #{inspect(key)} #{inspect(err)}")
          :error
      end

      @doc """
      Delete anything by its key.

      Returns a boolean indicating if element has been correctly deleted.
      """
      def delete(key), do: :ets.delete(@bucket, key)

      @doc """
      Obtain the number of elements stored in the cache.

      Returns an integer equals or bigger than zero.
      """
      def size(), do: :ets.select_count(@bucket, [{{:_, :_, :_}, [], [true]}])

      @doc """
      Delete everything in the cache.

      Returns a boolean indicating if cache has been correctly cleared.
      """
      def clear(), do: :ets.delete_all_objects(@bucket)

      defp get_keepalive(keepAliveInMillis) do
        if keepAliveInMillis == :keep_alive_forever do
          :keep_alive_forever
        else
          epoch_time(:millisecond) + keepAliveInMillis
        end
      end

      defp check_valid_keep_alive(keepAliveInMillis) do
        keepAliveInMillis != nil and
          (keepAliveInMillis == :keep_alive_forever or
             (is_integer(keepAliveInMillis) and keepAliveInMillis > 0))
      end

      def purge_cache() do
        now = epoch_time(:millisecond)

        :ets.select_delete(@bucket, [
          {{:_, :_, :"$1"}, [{:is_number, :"$1"}, {:"=<", :"$1", now}], [true]}
        ])
      end

      @impl true
      def init(state) do
        :ets.new(@bucket, [:set, :public, :named_table])
        {:ok, state, {:continue, :init_async}}
      end

      @impl GenServer
      @wait_purge 60_000
      def handle_continue(:init_async, state) do
        # this is all to randomly distribute the cleanups and reduce spikes
        # if there are a lot of caches
        delay = :rand.uniform(trunc(@wait_purge * 0.95))
        Process.sleep(delay)

        :timer.apply_interval(@wait_purge, __MODULE__, :purge_cache, [])

        {:noreply, state}
      end
    end
  end
end
