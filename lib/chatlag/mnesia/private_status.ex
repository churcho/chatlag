defmodule Chatlag.PrivateStatus do
  use Memento.Table,
    attributes: [:id, :room_id, :party_id, :user_id],
    # index: [:party_id, :user_id],
    type: :ordered_set,
    autoincrement: true
end
