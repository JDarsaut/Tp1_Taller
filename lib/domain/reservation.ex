defmodule Tp1Taller.Domain.Reservation do
  defstruct [
    :id,
    :passenger_id,
    :seat_id,
    :status # :pending - :confirmed - :cancelled - :expired
  ]
end
