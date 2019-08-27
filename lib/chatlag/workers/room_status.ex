defmodule Chatlag.RoomStatus do
  use Memento.Table,
    attributes: [:id, :room_id, :user_id, :nickname, :private, :party_id, :party],
    index: [:room_id, :user_id],
    type: :ordered_set,
    autoincrement: true
end
