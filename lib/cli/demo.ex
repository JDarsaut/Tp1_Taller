defmodule Tp1Taller.CLI.Demo do
  alias Tp1Taller.Domain.{Flight, Seat}
  alias Tp1Taller.Processes.FlightServer

  def run do
    seats =
      for id <- 1..5, into: %{} do
        {id, %Seat{id: id, status: :available, reservation_id: nil}}
      end

    flight = %Flight{id: "AR123", seats: seats, reservations: %{}}

    FlightServer.start_link(flight)

    IO.puts("Sistema iniciado 🚀")
  end
end