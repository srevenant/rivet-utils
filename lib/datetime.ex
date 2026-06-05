defmodule Rivet.Utils.DateTime do
  @minute_zero %{minute: 0, second: 0, microsecond: {0, 0}}
  @hour_zero Map.put(@minute_zero, :hour, 0)
  @day_one Map.put(@hour_zero, :day, 1)

  @sec_per_min 60
  @min_per_hour 60
  @sec_per_hour @sec_per_min * @min_per_hour

  @doc """
  iex> beginning_of_hour(~U[2026-05-12 19:43:50.393307Z])
  ~U[2026-05-12 19:00:00Z]
  iex> beginning_of_hour(~U[2027-11-21 11:23:20.333917Z])
  ~U[2027-11-21 11:00:00Z]
  iex> beginning_of_hour(~U[2020-01-01 00:00:00Z])
  ~U[2020-01-01 00:00:00Z]
  """
  @spec beginning_of_hour(DateTime.t()) :: DateTime.t()
  def beginning_of_hour(datetime), do: Map.merge(datetime, @minute_zero)

  @doc """
  iex> beginning_of_day(~U[2026-05-12 19:43:50.393307Z])
  ~U[2026-05-12 00:00:00Z]
  iex> beginning_of_day(~U[2027-11-21 11:23:20.333917Z])
  ~U[2027-11-21 00:00:00Z]
  iex> beginning_of_day(~U[2020-01-01 00:00:00Z])
  ~U[2020-01-01 00:00:00Z]
  """
  @spec beginning_of_day(DateTime.t()) :: DateTime.t()
  def beginning_of_day(datetime), do: Map.merge(datetime, @hour_zero)

  @doc """
  iex> beginning_of_month(~U[2026-05-12 19:43:50.393307Z])
  ~U[2026-05-01 00:00:00Z]
  iex> beginning_of_month(~U[2027-11-21 11:23:20.333917Z])
  ~U[2027-11-01 00:00:00Z]
  iex> beginning_of_month(~U[2020-01-01 00:00:00Z])
  ~U[2020-01-01 00:00:00Z]
  """
  @spec beginning_of_month(DateTime.t()) :: DateTime.t()
  def beginning_of_month(datetime), do: Map.merge(datetime, @day_one)

  @doc """
  iex> m4 = ~U[2026-04-12 00:00:00.00Z]
  iex> m5 = ~U[2026-05-12 00:00:00.00Z]
  iex> m6 = ~U[2026-06-12 00:00:00.00Z]
  iex> m7 = ~U[2026-07-12 00:00:00.00Z]
  iex> between?(m4, %{start_at: m4, end_at: m5})
  true
  iex> between?(m5, %{start_at: m4, end_at: m6})
  true
  iex> between?(m6, %{start_at: m6, end_at: m7})
  true
  iex> between?(m5, %{start_at: m6, end_at: m7})
  false
  """
  @spec between?(DateTime.t(), %{start_at: DateTime.t(), end_at: DateTime.t()}) :: boolean()
  def between?(date, %{start_at: start_at, end_at: end_at}) do
    start_at_t = DateTime.to_unix(start_at)
    end_at_t = DateTime.to_unix(end_at)
    date_t = DateTime.to_unix(date)
    start_at_t <= date_t and date_t <= end_at_t
  end

  @doc """
  iex> assert {:ok, ~U[2025-04-01 00:00:00Z]} = utc_new(2025, 4)
  iex> assert {:ok, ~U[2020-01-03 00:00:00Z]} = utc_new(2020, 1, 3)
  iex> assert {:error, :invalid_date} = utc_new(2025, 2, 30)
  iex> assert {:error, :invalid_date} = utc_new(2025, 4, 31)
  iex> assert {:error, :invalid_date} = utc_new(2025, 0, 3)
  iex> assert {:error, :invalid_date} = utc_new(2025, 1, 0)
  """
  @spec utc_new(integer(), pos_integer(), pos_integer()) :: {:ok, DateTime.t()} | {:error, atom()}
  def utc_new(year, month, day \\ 1) do
    with {:ok, date} <- Date.new(year, month, day),
         {:ok, time} <- Time.new(0, 0, 0) do
      DateTime.new(date, time, "Etc/UTC")
    end
  end

  @doc """
  iex> assert 24.0 = hours_between(~U[2025-04-01 00:00:00Z], ~U[2025-04-02 00:00:00Z])
  iex> assert 48.0 = hours_between(~U[2025-04-01 00:00:00Z], ~U[2025-04-03 00:00:00Z])
  iex> assert 3.0 = hours_between(~U[2025-04-01 00:00:00Z], ~U[2025-04-01 03:00:00Z])
  iex> assert +0.0 = hours_between(~U[2025-04-01 00:00:00Z], ~U[2025-04-01 00:00:00Z])
  iex> assert 0.5 = hours_between(~U[2025-04-01 00:00:00Z], ~U[2025-04-01 00:30:00Z])
  iex> assert -4.0 = hours_between(~U[2025-04-01 05:00:00Z], ~U[2025-04-01 01:00:00Z])
  """
  @spec hours_between(DateTime.t(), DateTime.t()) :: float()
  def hours_between(start_at, end_at),
    do: (DateTime.to_unix(end_at) - DateTime.to_unix(start_at)) / @sec_per_hour
end
