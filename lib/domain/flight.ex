defmodule Tp1Taller.Domain.Flight do
  defstruct [
    :id,
    seats: %{},
    reservations: %{}
  ]
end