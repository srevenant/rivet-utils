defmodule Rivet.Utils.LazyCache do
  @moduledoc """
  Hat tip to https://hex.pm/packages/lazy_cache
  """

  @callback get(key :: any()) :: {:ok, any()} | {:error, :not_found}
  @optional_callbacks [get: 1]

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @bucket String.to_atom("#{__MODULE__}.BUCKET")
      require Logger
      use GenServer
      @expires Keyword.get(opts, :expires, 300_000)
      @wait_prune Keyword.get(opts, :wait_prune, 60_000)

      @doc """
      Start scheduling the works for clearing the cache.
      This method should be called before performing any operation.

      Returns `{:ok, PID}`.
      """
      def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

      @doc """
      Store anything for a certain amount of time or forever if no keep alive time specified
      """
      @spec insert(any(), any(), pos_integer() | :infinity) :: true | {:error, String.t()}
      def insert(key, value, keepalive \\ :infinity) do
        if not valid_keepalive?(keepalive) do
          {:error, "Keep Alive Time is not valid. Should be a positive Integer or :infinity."}
        else
          :ets.insert(@bucket, {key, value, get_keepalive(keepalive)})
        end
      end

      @doc """
      Retrieve anything by its key using the raw :ets.lookup call. less idiomatic than get,
      but includes rescue for unexpected results that raise an error, instead turning
      it into :error after logging the reason.
      """
      def lookup(key) do
        :ets.lookup(@bucket, key)
      rescue
        err ->
          Logger.warning("Cache lookup fault #{inspect(@bucket)} #{inspect(key)} #{inspect(err)}")
          :error
      end

      @doc """
      Return the value of a key in an idiomatic tuple
      """
      def get(key) do
        case lookup(key) do
          [{_, val, _}] -> {:ok, val}
          _ -> {:error, :not_found}
        end
      end

      defoverridable get: 1

      @doc """
      Similar to get, but call a function to lookup the value if it isn't in the cache.
      """
      def get_through(key, func) do
        case lookup(key) do
          [{_, value, _}] ->
            {:ok, value}

          _ ->
            with {:ok, value} <- func.(key) do
              insert(key, value, @expires)
              {:ok, value}
            end
        end
      end

      @doc """
      Count of items in the cache.
      """
      def size(), do: :ets.info(@bucket, :size)
      def delete(key), do: :ets.delete(@bucket, key)
      def clear(), do: :ets.delete_all_objects(@bucket)

      defp get_keepalive(:infinity), do: :infinity
      defp get_keepalive(x), do: epoch_time() + x

      defp valid_keepalive?(keepalive) when keepalive == :infinity, do: true
      defp valid_keepalive?(keepalive) when is_integer(keepalive) and keepalive > 0, do: true
      defp valid_keepalive?(_), do: false

      defp epoch_time(), do: System.monotonic_time(:millisecond)

      @impl true
      def init(state) do
        :ets.new(@bucket, [:set, :public, :named_table, read_concurrency: true])

        # this is all to randomly distribute the cleanups and reduce spikes if
        # there are a lot of caches
        delay = :rand.uniform(trunc(@wait_prune * 0.95))
        Process.send_after(self(), :start_cache_cleaner, delay)

        {:ok, state}
      end

      @impl GenServer
      def handle_info(:start_cache_cleaner, state) do
        {:ok, ref} = :timer.send_interval(@wait_prune, self(), :prune_cache)
        {:noreply, Map.put(state, :ref, ref)}
      end

      # prune is inside this genserver, so if this takes long it can block cache calls
      # optionally can do a Process.send_after interval call-back solution  (ala
      # Interval)—if this becomes an issue -BJG
      def handle_info(:prune_cache, state) do
        now = epoch_time()

        :ets.select_delete(@bucket, [
          {{:_, :_, :"$1"}, [{:is_integer, :"$1"}, {:"=<", :"$1", now}], [true]}
        ])

        {:noreply, state}
      end

      @impl true
      def terminate(_, %{ref: ref}) do
        :timer.cancel(ref)
        :ok
      end

      def terminate(_, _), do: :ok
    end
  end
end
