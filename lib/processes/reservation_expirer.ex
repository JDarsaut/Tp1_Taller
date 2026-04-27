defmodule Tp1Taller.Processes.ReservationExpirer do
  def start(reservation_id, timeout_ms) do
    spawn(fn ->
      Process.sleep(timeout_ms)
      send(:flight_server, {:expire_reservation, reservation_id})
    end)
  end
end