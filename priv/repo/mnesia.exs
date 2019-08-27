#     mix run priv/repo/mnesia.exs

alias Chatlag.RoomStatus

nodes = [ node() ]

# Create the schema
Memento.stop
Memento.Schema.create(nodes)
Memento.start


Memento.Table.create!(RoomStatus, disc_copies: nodes)
# Memento.transaction! fn ->
#   Memento.Query.write(%RoomStatus{room_id: 12, user_id: 3, nickname: "Sarah Molton"})
# end

# Memento.transaction! fn ->
#   Memento.Query.all(RoomStatus)
# end