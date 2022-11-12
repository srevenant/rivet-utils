defmodule Rivet.Utils.Interval.TickHF do
  @moduledoc """
  High frequency interval tick - forced process state matching the interval's
  desired structure (optimal tuple instead of dict). Runs as an independent
  GenServer process.  Send "state data" into GenServer.start_link(state_data)

  How to use:

    1. `use Utils.IntervalTickHF, [opts]` (see below for options)
    2. define function `callback_name` which is called every frequency, with
       an extra option of `:tick`, and every interval with the option being
       `:tock`.  Spec:

       callback_name(
           state_data :: term(),
           :tick | :tock,
           last_run_time :: number()
       ) :: {:ok, state_data :: term()}

  Opts include:

  - `callback: atom()` — REQUIRED — function to call on each interval/frequency
  - `tick: number()` — REQUIRED - integer in the time_size matching get_time.
                       tick must be smaller than tock.  (i.e. 100 vs 1000).
  - `tock: number()` — REQUIRED - integer in the time_size matching get_time
                       tock must be large than tick.
  - `get_time: fn()` — how time is measured; defaults to `System.system_time(:second)`
  - `millis_factor: 1000` — a multiplier to convert time from get_time into millis.
  - `handle_interval: :hf_interval_tick` — change the handle_info(:callback, ..)
     name — largely unecessary to adjust unless the default :hf_interval_tick
     collides with something else already being in handle_info(..)

  Example:

    defmodule SensorReader do
      use IntervalTickHF,
        callback: :sample_power,
        get_time: System.system_time(:millisecond),
        interval: 1000,
        frequency: 10,
        millis_factor: 1

      def sample_power({config, samples}, :tick, _) do
        {:ok, {config, [read_value(config) | samples]}}
      end

      def sample_power({config, samples}, :tock, _) do
        Report.Value.somehow( [read_value(config) | samples] |> normalize_samples())
        {:ok, {config, []}}
      end

      defp read_value(config), do: ...
      defp normalize_samples(samples), do: ...
    end

  Started with:

    SensorReader.start_link({%{config_data_here}, []}, name: :the_sensor)

  Contributor: Brandon Gillespie
  """
  require Logger
  @type time_number() :: integer()
  @type interval_state() :: {
          state_data :: any(),
          next_tock :: time_number(),
          last_tick :: time_number(),
          timer_ref :: reference()
        }

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer

      @callback_name Keyword.get(opts, :callback)
      @interval Keyword.get(opts, :tock)
      @frequency Keyword.get(opts, :tick)
      @get_time Keyword.get(opts, :get_time, fn -> System.system_time(:second) end)
      @millis_factor Keyword.get(opts, :millis_factor, 1000)
      @handle_interval Keyword.get(opts, :handle_interval, :hf_interval_tick)

      defp get_interval_time(), do: @get_time

      def start_link(state_data, opts \\ []),
        do: GenServer.start_link(__MODULE__, state_data, opts)

      ##########################################################################
      @impl GenServer
      def init(state_data) do
        ref = queue_next_interval()
        now = get_interval_time()
        {:ok, {state_data, now + @interval, now, ref}}
      end

      ##########################################################################
      @impl GenServer
      @spec handle_info(@handle_interval, interval_state()) :: {:noreply, interval_state()}
      def handle_info(@handle_interval, {data, next_tock, last, _}) do
        now = get_interval_time()

        {next_tock, tick_tock} =
          if now >= next_tock do
            {now + inter, :tock}
          else
            {next_tock, :tick}
          end

        ref = queue_next_interval()

        try do
          with {:ok, data} <- apply(__MODULE__, @callback_name, [data, tick_tock, last]) do
            {:noreply, {data, next_tock, now, ref}}
          else
            error ->
              IO.inspect(error, label: "Unexpected result from Interval call")
              {:noreply, {data, next_tock, now, ref}}
          end
        rescue
          err ->
            Logger.error(Exception.format(:error, err, __STACKTRACE__))
            {:noreply, {data, next_tock, get_interval_time(), ref}}
        end
      end

      ##########################################################################
      @spec queue_next_interval(time_number()) :: reference()
      def queue_next_interval(),
        do: Process.send_after(self(), @handle_interval, @frequency * @millis_factor)

      ##########################################################################
      def stop(pid), do: GenServer.call(pid, :stop)

      def handle_call(:stop, _, {_, _, _, ref}) do
        Process.cancel_timer(ref)
        :stop
      end
    end
  end
end
