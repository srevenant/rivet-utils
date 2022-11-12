defmodule Rivet.Utils.Interval do
  @moduledoc """
  Make sure only one of a method callback is ever running.

  Interval and last run time are stored in state.  You can adjust interval
  on the fly, but it'll kick in on second iteration after this one because
  the next one is already queued.

  Contributor: Brandon Gillespie
  """
  import Rivet.Utils.Time, only: [epoch_time: 1]
  require Logger

  @margin 2

  defmacro __using__(_) do
    quote location: :keep do
      def handle_info({:intervals, method}, state) do
        state =
          case get_in(state, [:intervals, method]) do
            {_, interval} ->
              Rivet.Utils.Interval.queue(state, method, interval)

            nil ->
              state
          end

        with {:ok, state} <- apply(__MODULE__, method, [state]) do
          {:noreply, state}
        else
          error ->
            IO.inspect(error, label: "Unexpected result from Interval call")
            {:noreply, state}
        end
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          {:noreply, state}
      end
    end
  end

  def start(state, method, interval) do
    last =
      case get_in(state, [:intervals, method]) do
        nil -> 0
        {last, _} -> last
      end

    now = epoch_time(:millisecond)
    diff = now - last

    if diff < interval * @margin do
      # we've seen it within 2x the interval, so it's likely already running,
      # don't start another...
      state
    else
      queue(state, method, interval)
    end
  rescue
    err ->
      Logger.error(Exception.format(:error, err, __STACKTRACE__))
      state
  end

  def stop(state, method) do
    intervals =
      Map.get(state, :intervals, %{})
      |> Map.delete(method)

    Map.put(state, :intervals, intervals)
  end

  def queue(state, method, interval) do
    now = epoch_time(:millisecond)
    Process.send_after(self(), {:intervals, method}, interval)

    intervals =
      Map.get(state, :intervals, %{})
      |> Map.put(method, {now, interval})

    Map.put(state, :intervals, intervals)
  end
end
