defmodule Chatlag.Contact do
  # import Ecto.Query, warn: false

  alias Chatlag.Emails.ContactForm

  def send(contact_params, params) do
    IO.inspect(contact_params)
    IO.inspect(params)

    contact_params
  end
end
