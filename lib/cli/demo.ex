defmodule Tp1Taller.CLI.Demo do
  alias Tp1Taller.Domain.{Flight, Seat}
  alias Tp1Taller.Processes.FlightServer

  def run do
    IO.puts("\n=== INICIANDO DEMO CONDOR DEL SUR ===\n")

    #Creo el vuelo
    seats =
      for id <- 1..5, into: %{} do
        {id, %Seat{id: id, status: :available, reservation_id: nil}}
      end

    flight = %Flight{id: "AR123", seats: seats, reservations: %{}}

    FlightServer.start_link(flight)

    IO.puts("Vuelo creado con 5 asientos\n")

#----------- concurrencia ---------------------

    IO.puts(">> Dos pasajeros intentan reservar el asiento 1 al mismo tiempo")

    parent = self()

    spawn(fn ->
      send(:flight_server, {:reserve, "Pasajero A", 1, parent})
    end)

    spawn(fn ->
      send(:flight_server, {:reserve, "Pasajero B", 1, parent})
    end)

    r1 = receive do msg -> msg end
    r2 = receive do msg -> msg end

    IO.puts("Resultados:")
    IO.inspect(r1)
    IO.inspect(r2)
    IO.puts("")

#----------- confirmacion ---------------------

    IO.puts(">> Reservando asiento 2 para confirmar")

    send(:flight_server, {:reserve, "Pasajero C", 2, self()})

    {:ok, res_confirm} =
      receive do
        msg -> msg
      end

    IO.puts("Confirmando reserva...")

    send(:flight_server, {:confirm, res_confirm, self()})

    receive do
      {:ok, :processing_payment} ->
        IO.puts("Procesando pago...")
    end

    receive do
      {:payment_confirmed, res_id} ->
        IO.puts("Pago confirmado para reserva #{inspect(res_id)}")
    end

    IO.puts("")

   #----------- cancelacion ---------------------

    IO.puts(">> Reservando asiento 3 para cancelar")

    send(:flight_server, {:reserve, "Pasajero D", 3, self()})

    {:ok, res_cancel} =
      receive do
        msg -> msg
      end

    IO.puts("Cancelando reserva...")

    send(:flight_server, {:cancel, res_cancel, self()})

    IO.inspect(receive do msg -> msg end)
    IO.puts("")

    #----------- expiracion ---------------------

    IO.puts(">> Reservando asiento 4 (se va a expirar en 30s)")

    send(:flight_server, {:reserve, "Pasajero E", 4, self()})

    {:ok, _res_exp} =
      receive do
        msg -> msg
      end

    IO.puts("Esperando expiración...\n")

    Process.sleep(31_000)

    IO.puts("Intentando reservar asiento 4 nuevamente...")

    send(:flight_server, {:reserve, "Pasajero F", 4, self()})

    IO.inspect(receive do msg -> msg end)

    IO.puts("\n=== FIN DEMO ===\n")
  end
end
