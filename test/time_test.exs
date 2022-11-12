defmodule Rivet.Utils.Test.Time do
  use ExUnit.Case
  doctest Rivet.Utils.Time, import: true
  alias Rivet.Utils.Time

  test "time_range" do
    now = DateTime.utc_now()

    Enum.each(
      [
        ["1d", 86_400],
        ["2.5 days", 216_000],
        ["2.5h", 9000],
        ["2h", 7200],
        ["20m", 1200],
        ["20min", 1200],
        ["20 min", 1200],
        ["20", 1200],
        # because we round to a minute
        ["20s", 0],
        # because we round to a minute
        ["120s", 120],
        ["8:45 am", 0],
        ["8:45a", 0],
        ["8:45p", 0],
        ["10:25a+5min", 300],
        ["10:25p + 1 hours", 3600],
        ["10:25a - 14:20", 14_100],
        ["12:00-13:30", 5400]
      ],
      fn arg ->
        [input, elapsed] = arg
        {:ok, _d1, _d2, seconds} = Time.time_range(input, now)
        assert elapsed == seconds
      end
    )

    {:ok, time1, _} = DateTime.from_iso8601("#{DateTime.to_date(DateTime.utc_now())} 12:00:00Z")
    {:ok, time2, _} = DateTime.from_iso8601("#{DateTime.to_date(DateTime.utc_now())} 15:30:00Z")
    assert {:ok, time1, time2, 12_600} == Time.time_range("12:00-3:30")
  end

  describe "start_datetime_of_posix_interval/4" do
    setup do
      {:ok, midnight_plus_forty_sec_dec1} = DateTime.new(~D[2021-12-01], ~T[00:00:40], "Etc/UTC")

      {:ok, midnight_plus_forty_sec_dec1: midnight_plus_forty_sec_dec1}
    end

    @one_minute_in_milliseconds 60_000
    test "Finds start datetime of a posix interval", %{
      midnight_plus_forty_sec_dec1: midnight_plus_forty_sec
    } do
      # works for seconds
      assert DateTime.add(midnight_plus_forty_sec, 20, :second) ==
               Time.start_datetime_of_posix_interval(midnight_plus_forty_sec, 60, :second, 1)

      # works for milliseconds
      assert DateTime.add(midnight_plus_forty_sec, 20, :second) ==
               Time.start_datetime_of_posix_interval(
                 midnight_plus_forty_sec,
                 @one_minute_in_milliseconds,
                 :millisecond,
                 1
               )
    end

    @one_hour_in_seconds 3_600
    test "Doesn't just add time",
         %{midnight_plus_forty_sec_dec1: midnight_plus_forty_sec} do
      {:ok, one_am_plus_forty_sec_dec1} = DateTime.new(~D[2021-12-01], ~T[01:00:40], "Etc/UTC")

      refute one_am_plus_forty_sec_dec1 ==
               Time.start_datetime_of_posix_interval(
                 midnight_plus_forty_sec,
                 @one_hour_in_seconds,
                 :second,
                 1
               )

      {:ok, one_am_dec1} = DateTime.new(~D[2021-12-01], ~T[01:00:00], "Etc/UTC")

      assert ^one_am_dec1 =
               Time.start_datetime_of_posix_interval(
                 midnight_plus_forty_sec,
                 @one_hour_in_seconds,
                 :second,
                 1
               )
    end
  end
end
