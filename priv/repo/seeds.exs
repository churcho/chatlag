# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Chatlag.Repo.insert!(%Chatlag.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Chatlag.Chat
alias Chatlag.Chat.Room
alias Chatlag.Repo
alias Chatlag.Chat.Message

Repo.delete_all(Message)
Repo.delete_all(Room)

Enum.each(1..40, fn(room_num) ->
  onF = room_num < 5

  Chat.create_room(%{title: "חדר מספר #{room_num}", slogen: "חדר לאוהבי #{room_num}", attached: "מה נעוץ בחדר", min_age: 14, on_front: onF})
end)
