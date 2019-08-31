defmodule Chatlag.PrivateStatus do
  use Memento.Table,
    attributes: [:id, :room_id, :user_id, :party_id, :is_online],
    index: [:party_id, :user_id],
    type: :ordered_set,
    autoincrement: true
end
