defmodule Rivet.Utils.Time do
  @moduledoc """
  Contributor: Brandon Gillespie
  """

  import Transmogrify.As, only: [as_float: 1]
  import Rivet.Utils.Enum, only: [enum_rx: 2]

  def ifloor(number) when is_float(number), do: Kernel.trunc(number)
  def ifloor(number) when is_integer(number), do: number

  # Test only works half the year thanks to daylight saving shift
  # @doc """
  # iex> utc_offset(:string)
  # "-06:00"
  # iex> utc_offset(:minutes)
  # -360
  # iex> utc_offset(:hour_min)
  # {-6, 0}
  # """
  def utc_offset(:string) do
    p = fn x -> String.pad_leading("#{x}", 2, "0") end

    case :calendar.time_difference(:calendar.universal_time(), :calendar.local_time()) do
      {0, {hour, min, _}} -> "+#{p.(hour)}:#{p.(min)}"
      {-1, {hour, min, _}} -> "-#{p.(24 - hour)}:#{p.(min)}"
    end
  end

  def utc_offset(:minutes) do
    case :calendar.time_difference(:calendar.universal_time(), :calendar.local_time()) do
      {0, {hour, min, _}} -> hour * 60 + min
      {-1, {hour, min, _}} -> (hour - 24) * 60 - min
    end
  end

  def utc_offset(:hour_min) do
    case :calendar.time_difference(:calendar.universal_time(), :calendar.local_time()) do
      {0, {hour, min, _}} -> {hour, min}
      {-1, {hour, min, _}} -> {hour - 24, -min}
    end
  end

  def iso_time_range(input) when is_binary(input) do
    case String.split(input, "/") do
      [stime, etime] ->
        iso_time_range(stime, etime)

      _other ->
        {:error, "Input #{input} is not a valid ISO time range"}
    end
  end

  def iso_time_range(stime, etime) when is_binary(stime) and is_binary(etime) do
    with {:ok, d_stime = %DateTime{}, _offset} <- DateTime.from_iso8601(stime),
         {:ok, d_etime = %DateTime{}, _offset} <- DateTime.from_iso8601(etime) do
      {:ok, d_stime, d_etime, DateTime.to_unix(d_etime) - DateTime.to_unix(d_stime)}
    else
      {:error, reason} ->
        IO.inspect(reason, label: "processing time error")
        {:error, "Unable to process time: #{reason} #{stime}/#{etime}"}
    end
  end

  #### Disabled because it requires us to include Timex
  # @doc """
  # Iterate a map and merge string & atom keys into just atoms.
  # Not recursive, only top level.
  # Behavior with mixed keys being merged is not guaranteed, as maps are not always
  # ordered.
  #
  # ## Examples
  #
  # iex> {:ok, %DateTime{}, %DateTime{}, elapsed} = time_range("20 min")
  # iex> elapsed
  # 1200
  # """
  # def time_range(input) do
  #   time_range(input, DateTime.utc_now())
  # end
  #
  # def time_range(input, %DateTime{} = reference) do
  #   # regex list of supported variants
  #   time_rxs = [
  #     {~r/^\s*((\d+):(\d+))\s*((p|a)m?)?\s*$/i,
  #      fn match, _time ->
  #        stime = time_at_today(match, reference)
  #        {stime, stime}
  #      end},
  #     {~r/^\s*((\d+):(\d+))\s*((p|a)m?)?\s*-\s*(.+)\s*$/i,
  #      fn match, _time ->
  #        stime = time_at_today(Enum.slice(match, 0, 6), reference)
  #
  #        case time_at_today(Enum.at(match, 6), reference) do
  #          nil ->
  #            nil
  #
  #          %DateTime{} = etime ->
  #            etime =
  #              if etime < stime do
  #                # assume 12hrs left off
  #                Timex.shift(etime, hours: 12)
  #              else
  #                etime
  #              end
  #
  #            {stime, etime}
  #        end
  #      end},
  #     {~r/^\s*((\d+):(\d+))\s*((p|a)m?)?\s*\+\s*(.+)\s*$/i,
  #      fn match, _time ->
  #        stime = time_at_today(Enum.slice(match, 0, 6), reference)
  #
  #        case time_duration(Enum.at(match, 6)) do
  #          nil ->
  #            nil
  #
  #          mins ->
  #            {stime, Timex.shift(stime, minutes: mins)}
  #        end
  #      end},
  #     {~r/^\s*([0-9.]+)\s*([a-z]+)?$/i,
  #      fn match, _time ->
  #        case time_duration(match) do
  #          nil ->
  #            nil
  #
  #          mins ->
  #            {Timex.shift(reference, minutes: -mins), reference}
  #        end
  #      end}
  #   ]
  #
  #   case enum_rx(time_rxs, input) do
  #     nil ->
  #       {:error, "Sorry, I don't understand the time range #{inspect(input)}"}
  #
  #     {stime, etime} ->
  #       {:ok, stime, etime, Timex.to_unix(etime) - Timex.to_unix(stime)}
  #   end
  # end
  #
  # def hr_to_zulu(hr, ""), do: hr
  # def hr_to_zulu(hr, "A"), do: hr
  #
  # def hr_to_zulu(hr, "P") do
  #   hr + 12
  # end
  #
  # def time_at_today(input, reference) when is_binary(input),
  #   do: time_at_today(Regex.run(~r/^\s*((\d+):(\d+))\s*((p|a)m?)?$/i, input), reference)
  #
  # def time_at_today(nil, _reference), do: nil
  #
  # def time_at_today(regmatch, reference) do
  #   {mhr, mmin} =
  #     case regmatch do
  #       [_, _, hr, min] ->
  #         {as_int!(hr, 0), as_int!(min, 0)}
  #
  #       [_, _, hr, min, _ampm, ap] ->
  #         {as_int!(hr, 0) |> hr_to_zulu(String.upcase(ap)), as_int!(min, 0)}
  #     end
  #
  #   # this is a fail if we don't consider timezone
  #   # drop today's time, then add it back in
  #   reference
  #   |> Timex.to_date()
  #   |> Timex.to_datetime()
  #   |> Timex.shift(hours: mhr)
  #   |> Timex.shift(minutes: mmin)
  #
  #   #    now_t = Timex.to_unix(reference)
  #   #    midnight_t = now_t - rem(now_t, 86400)
  #   #    adjusted_t = midnight_t + mhr * 3600 + mmin * 60
  #   #    DateTime.from_unix!(adjusted_t)
  # end

  def time_duration([match, match1]), do: time_duration([match, match1, ""])

  def time_duration([_match, match1, match2]) do
    to_minutes(match1, match2)
  end

  def time_duration(input) when is_binary(input) do
    time_duration(Regex.run(~r/^\s*([0-9.]+)\s*([a-z]+)?/i, input))
  end

  def time_duration(nil), do: nil

  def to_minutes(number, label) do
    {:ok, num} = as_float(number)

    enum_rx(
      [
        {~r/^(m|min(s)?|minute(s)?)$/, fn _, _ -> num end},
        {~r/^(h|hr(s)?|hour(s)?)$/, fn _, _ -> num * 60 end},
        {~r/^(d|day(s)?)$/, fn _, _ -> num * 60 * 24 end},
        {~r/^(s|sec(s)?|second(s)?)$/, fn _, _ -> num / 60 end},
        {~r/now/, fn _, _ -> 0 end},
        {~r//, fn _, _ -> num end}
      ],
      label
    )
    |> ifloor
  end

  @doc """
  this wraps the complexities brought on by Erlang being fancy with time,
  and gives us a conventional posix/epoch time value.  The time value to
  return is specified by the first argument, as an atom, and is a required
  argument (to remove ambiguity), from the set:

    :second, :millisecond, :microsecond or :nanosecond

  It also uses their best value for 'monotonic' time so the clock will
  not go backwards.

  For the full story see:
    https://hexdocs.pm/elixir/System.html
    http://erlang.org/doc/apps/erts/time_correction.html
  """
  @spec epoch_time(time_type :: atom) :: integer
  def epoch_time(time_type \\ :second)
      when time_type in [:second, :millisecond, :microsecond, :nanosecond] do
    System.monotonic_time(time_type) + System.time_offset(time_type)
  end

  # and this is just system time to avoid an extra + time_offset operation
  def now(), do: System.system_time(:second)
  def now(time_type), do: System.system_time(time_type)

  ######################################################################################################################
  @doc """
  start_datetime_of_posix_interval/4.

  Suppose you have a DateTime that is 30 seconds past the beginning of a given minute. If the interval is 60_000
  milliseconds (1 min.), then the beginning of the next posix interval is 30 seconds later- this returns that datetime.
  """
  @spec start_datetime_of_posix_interval(
          DateTime.t(),
          integer(),
          interval_unit :: :second | :millisecond,
          integer()
        ) ::
          DateTime.t()
  def start_datetime_of_posix_interval(
        datetime,
        interval,
        :second,
        num_of_intervals_back_or_forward
      ) do
    fn posix_time -> div(posix_time, interval) end
    |> do_find_start(datetime, interval, :second, num_of_intervals_back_or_forward)
  end

  @second_to_millisecond_unit_converter 1_000
  def start_datetime_of_posix_interval(
        datetime,
        interval,
        :millisecond,
        num_of_intervals_back_or_forward
      ) do
    fn posix_time -> div(posix_time * @second_to_millisecond_unit_converter, interval) end
    |> do_find_start(datetime, interval, :millisecond, num_of_intervals_back_or_forward)
  end

  ######################################################################################################################
  @spec do_find_start(fun(), DateTime.t(), integer(), :second | :millisecond, integer()) ::
          DateTime.t()
  defp do_find_start(
         posix_interval_func,
         datetime,
         interval,
         unit,
         num_of_intervals_back_or_forward
       ) do
    datetime
    |> DateTime.to_unix()
    |> then(posix_interval_func)
    |> Kernel.+(num_of_intervals_back_or_forward)
    |> Kernel.*(interval)
    |> DateTime.from_unix(unit)
    |> then(fn {:ok, datetime} -> DateTime.truncate(datetime, :second) end)
  end

  @hour_in_seconds 3_600
  @midnight ~T[00:00:00]
  @doc """
  utc_hours_since_midnight_sunday/0.

  There are 168 hours in a week, we zero-index them from 12:00:00 a.m. UTC Sunday.

  """
  @spec utc_hours_since_midnight_sunday() :: 0..167
  def utc_hours_since_midnight_sunday() do
    utc_now = DateTime.utc_now()

    utc_now
    |> Date.beginning_of_week()
    # beginning of week is Monday, subtract one day for Sunday
    |> Date.add(-1)
    |> DateTime.new(@midnight)
    |> then(fn {:ok, sunday_midnight} -> DateTime.to_unix(sunday_midnight) end)
    |> then(fn unix_sunday_midnight ->
      div(DateTime.to_unix(utc_now) - unix_sunday_midnight, @hour_in_seconds)
    end)
  end

  @doc """
  Provide the time in a "x hours/mins/seconds/etc" ago type format.
  Options. Time can be provided as posix epoch (preferred), or DateTime,
  or NaiveDateTime.

  - `since: time` — compare vs this time instead of "now"
  - `format: :long | :short(default) | :abbrev`
      - long format uses no shortened words (minute, second)
      - short (default) uses 'min' and 'sec' instead of the longer forms
      - abbrev uses one and two character abbreviations
  - `space: " "` (default)

  Examples:

  iex> (epoch_time() - 60) |> ago()
  "1 min"

  iex> (epoch_time() - 11000) |> ago()
  "3 hours"

  iex> DateTime.from_unix!(epoch_time() - 86400) |> ago(format: :abbrev, space: "")
  "1d"

  iex> ago(epoch_time() - 300, format: :long)
  "5 minutes"

  iex> t_start = epoch_time() - 900
  iex> t_end = epoch_time() - 300
  iex> ago(t_start, since: t_end, format: :long)
  "10 minutes"
  iex> ago(t_end, since: t_start, format: :long)
  "10 minutes"
  """
  @second 0
  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @week @day * 7
  @month @day * 30
  @year @day * 365

  @breaks [@year, @month, @week, @day, @hour, @minute, @second]

  @abbrevs %{
    :short => %{
      @second => "sec",
      @minute => "min",
      @hour => "hour",
      @day => "day",
      @week => "week",
      @month => "month",
      @year => "year"
    },
    :long => %{
      @second => "second",
      @minute => "minute",
      @hour => "hour",
      @day => "day",
      @week => "week",
      @month => "month",
      @year => "year"
    },
    :abbrev => %{
      @second => "s",
      @minute => "m",
      @hour => "hr",
      @day => "d",
      @week => "wk",
      @month => "mo",
      @year => "yr"
    }
  }

  def ago(from_time, opts \\ [])

  def ago(from_time, opts) when is_integer(from_time) do
    from_time = as_epoch(from_time)
    to_time = Keyword.get_lazy(opts, :since, fn -> epoch_time() end) |> as_epoch()
    space = Keyword.get(opts, :space, " ")

    labels = @abbrevs[Keyword.get(opts, :format, :short)]
    diff = abs(to_time - from_time)

    case {diff, Enum.find(@breaks, fn x -> diff >= x end)} do
      {diff, @second} when diff <= 1 -> "seconds"
      {diff, @second} -> "#{diff}#{space}seconds"
      {diff, type} -> divtrunc(diff, type, labels[type], space)
    end
  end

  def ago(from_time, opts), do: ago(as_epoch(from_time), opts)

  defp with_s(v, label, space) when v == 1, do: "#{v}#{space}#{label}"
  defp with_s(v, label, space), do: "#{v}#{space}#{label}s"
  defp divtrunc(x, y, label, space), do: Integer.floor_div(x, y) |> with_s(label, space)

  @doc """
  Because posix epoch time is just easier to work with once you understand how
  it works.
  """
  def as_epoch(%DateTime{} = t), do: DateTime.to_unix(t)

  def as_epoch(%NaiveDateTime{} = t),
    do: DateTime.from_naive!(t, "Etc/UTC") |> DateTime.to_unix(t)

  def as_epoch(x) when is_integer(x), do: x
end
