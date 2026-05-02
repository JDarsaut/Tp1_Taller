defmodule Tp1Taller.Processes.FlightServer do
  alias Tp1Taller.Domain.Flight

  #crea un nuevo proceso concurrente y con register le asigna un nombre global.
  def start_link(initial_flight) do
    pid = spawn_link(fn -> loop(initial_flight) end)
    Process.register(pid, :flight_server)
    pid
  end

  #espera mensajes por el receive, cuando un mensaje llega, llama a una funcion para manejarlo y se llama
  #recursivamente para actualizarse.
  defp loop(state) do
    receive do
      msg ->
        new_state = handle_message(msg, state)
        loop(new_state)
    end
  end

  #funcion para reservar el asiento
  defp handle_message({:reserve, passenger_id, seat_id, from}, state) do
    seat = Map.get(state.seats, seat_id)

    cond do
      #si el asiento no existe tirar error
      seat == nil ->
        send(from, {:error, :seat_not_found})
        state

      #si el asiento no esta disponible tirar error
      seat.status != :available ->
        send(from, {:error, :seat_not_available})
        state

      #si el asiento esta disponible, bloquearlo (TODAVIA NO CONFIRMADO)
      true ->
        reservation_id = make_ref()

        reservation = %{
          id: reservation_id,
          passenger_id: passenger_id,
          seat_id: seat_id,
          status: :pending
        }

        updated_seat = %{seat | status: :reserved, reservation_id: reservation_id}

        new_state = %{
          state
          | seats: Map.put(state.seats, seat_id, updated_seat),
            reservations: Map.put(state.reservations, reservation_id, reservation)
        }

        send(from, {:ok, reservation_id})

        Tp1Taller.Processes.ReservationExpirer.start(reservation_id, 30_000)

        new_state
    end
  end

  #funcion para manejar reserva que no se confirmo
  defp handle_message({:expire_reservation, reservation_id}, state) do
  case Map.get(state.reservations, reservation_id) do
    #si no existe, no hago nada
    nil ->
      state

    #si existe, en caso de que este pendiente la elimino
    reservation ->
      if reservation.status == :pending do
        seat = Map.get(state.seats, reservation.seat_id)

        updated_seat = %{
          seat
          | status: :available,
            reservation_id: nil
        }

        updated_reservation = %{
          reservation
          | status: :expired
        }

        %{
          state
          | seats: Map.put(state.seats, seat.id, updated_seat),
            reservations: Map.put(state.reservations, reservation_id, updated_reservation)
        }
      else
        state
      end
  end
end

defp handle_message({:cancel, reservation_id, from}, state) do
  case Map.get(state.reservations, reservation_id) do
    nil ->
      send(from, {:error, :reservation_not_found})
      state

    reservation ->
      if reservation.status != :pending do
        send(from, {:error, :invalid_reservation_state})
        state
      else
        seat = Map.get(state.seats, reservation.seat_id)

        updated_reservation = %{
          reservation | status: :cancelled
        }

        updated_seat = %{
          seat | status: :available, reservation_id: nil
        }

        new_state = %{
          state
          | reservations: Map.put(state.reservations, reservation_id, updated_reservation),
            seats: Map.put(state.seats, seat.id, updated_seat)
        }

        send(from, {:ok, reservation_id})

        new_state
      end
  end
end

defp handle_message({:confirm, reservation_id, from}, state) do
  case Map.get(state.reservations, reservation_id) do
    nil ->
      send(from, {:error, :reservation_not_found})
      state

    reservation ->
      if reservation.status != :pending do
        send(from, {:error, :invalid_reservation_state})
        state
      else
        seat = Map.get(state.seats, reservation.seat_id)

        updated_reservation = %{
          reservation | status: :confirmed
        }

        updated_seat = %{
          seat | status: :confirmed
        }

        new_state = %{
          state
          | reservations: Map.put(state.reservations, reservation_id, updated_reservation),
            seats: Map.put(state.seats, seat.id, updated_seat)
        }

        send(from, {:ok, reservation_id})

        new_state
      end
  end
end

  defp handle_message(msg, state) do
    IO.puts("Mensaje recibido: #{inspect(msg)}")
    state
  end
end
