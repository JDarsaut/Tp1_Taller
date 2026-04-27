defmodule Tp1Taller.Domain.Seat do
  defstruct [
  :id,
  :status, # :available - :reserved - :confirmed
  :reservation_id
]
end
