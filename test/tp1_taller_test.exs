defmodule Tp1TallerTest do
  use ExUnit.Case

  alias Tp1Taller.Domain.{Flight, Seat}
  alias Tp1Taller.Processes.FlightServer

  defp setup_flight do
    seats =
      for id <- 1..3, into: %{} do
        {id, %Seat{id: id, status: :available, reservation_id: nil}}
      end

    %Flight{id: "AR123", seats: seats, reservations: %{}}
  end

  defp receive_msg do
    receive do
      msg -> msg
    after
      1000 -> flunk("No se recibió respuesta")
    end
  end

  test "reserva asiento disponible" do
    pid = FlightServer.start_link(setup_flight())

    send(pid, {:reserve, 1, 1, self()})

    assert {:ok, _} = receive_msg()
  end

  test "no reserva asiento ocupado" do
    pid = FlightServer.start_link(setup_flight())

    send(pid, {:reserve, 1, 1, self()})
    receive_msg()

    send(pid, {:reserve, 2, 1, self()})

    assert {:error, :seat_not_available} = receive_msg()
  end

  test "confirmación inicia procesamiento de pago" do
    pid = FlightServer.start_link(setup_flight())

    send(pid, {:reserve, 1, 1, self()})
    {:ok, res_id} = receive_msg()

    send(pid, {:confirm, res_id, self()})

    assert {:ok, :processing_payment} = receive_msg()
  end

  test "cancelar reserva pendiente libera el asiento" do
    pid = FlightServer.start_link(setup_flight())

    send(pid, {:reserve, 1, 1, self()})
    {:ok, res_id} = receive_msg()

    send(pid, {:cancel, res_id, self()})
    assert {:ok, _} = receive_msg()

    send(pid, {:reserve, 2, 1, self()})
    assert {:ok, _} = receive_msg()
  end

  test "no se puede cancelar una reserva confirmada" do
    pid = FlightServer.start_link(setup_flight())

    send(pid, {:reserve, 1, 1, self()})
    {:ok, res_id} = receive_msg()

    send(pid, {:confirm, res_id, self()})
    receive_msg()

    receive do
      {:payment_confirmed, ^res_id} -> :ok
    after
      2000 -> flunk("No se confirmó el pago")
    end

    send(pid, {:cancel, res_id, self()})

    assert {:error, :invalid_reservation_state} = receive_msg()
  end

  test "reserva expira y libera el asiento" do
    pid = FlightServer.start_link(setup_flight())

    send(pid, {:reserve, 1, 1, self()})
    {:ok, _res_id} = receive_msg()

    Process.sleep(31_000)

    send(pid, {:reserve, 2, 1, self()})

    assert {:ok, _} = receive_msg()
  end
end
