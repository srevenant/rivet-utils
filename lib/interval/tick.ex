defmodule Rivet.Utils.Interval.Tick do
  @moduledoc """
  Similar to Interval, but tick-driven, where it has a tick frequency which is
  more frequent than the interval frequency -- allowing for interruptions to
  the interval and the subsequent intervals to start from there forward.

  Seconds used as precision, not milliseconds

  Contributor: Brandon Gillespie
  """
  import Rivet.Utils.Time, only: [epoch_time: 1]
  require Logger

  @margin 2

  defmacro __using__(_) do
    quote location: :keep do
      def handle_info({:interval_tick, method}, state) do
        case get_in(state, [:intervals, method]) do
          {_, {inter, freq, next}} ->
            now = epoch_time(:second)
            # IO.puts("#{now} <> #{inter}/#{freq}/#{next}")

            {next, flag} =
              if now >= next do
                {now + inter, :tock}
              else
                {next, :tick}
              end

            # queue the next tick
            state = Rivet.Utils.Interval.Tick.queue(state, method, inter, freq, next)

            # and see if we should do something on this one
            # IO.puts("#{epoch_time(:second)} #{flag} #{method}")

            with {:ok, state} <- apply(__MODULE__, method, [state, flag]) do
              {:noreply, state}
            else
              error ->
                IO.inspect(error, label: "Unexpected result from Interval call")
                {:noreply, state}
            end

          nil ->
            {:noreply, state}
        end
      rescue
        err ->
          Logger.error(Exception.format(:error, err, __STACKTRACE__))
          {:noreply, state}
      end
    end
  end

  def start(state, method, interval, freq) do
    last =
      case get_in(state, [:intervals, method]) do
        nil -> 0
        {last, _} -> last
      end

    now = epoch_time(:second)

    if now - last < interval * @margin do
      # we've seen it within 2x the interval, so it's likely already running,
      # don't start another...
      state
    else
      queue(state, method, interval, freq, now + freq)
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

  def queue(state, method, interval, frequency, next) do
    # IO.puts("#{epoch_time(:second)} queue")
    now = epoch_time(:second)
    Process.send_after(self(), {:interval_tick, method}, frequency * 1000)

    intervals =
      Map.get(state, :intervals, %{})
      |> Map.put(method, {now, {interval, frequency, next}})

    Map.put(state, :intervals, intervals)
  end

  def reset_next_interval(state, method) do
    case get_in(state, [:intervals, method]) do
      nil ->
        Logger.error("Cannot reset interval that is not configured: #{method}")
        state

      {_, {inter, freq, _}} ->
        # IO.puts("#{epoch_time(:second)} resetting interval")
        now = epoch_time(:second)
        put_in(state, [:intervals, method], {now, {inter, freq, now + inter}})
    end
  end
end
