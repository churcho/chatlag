defmodule Chatlag.Emails do
  # import Bamboo.Email

  alias Chatlag.Contacts
  alias Chatlag.Contacts.Contact

  # efratzaror2014
  def contact_email(%{email: email, message: message, name: name}) do
    message = message |> String.replace(~r/\n/, "<br>", global: true)

    contact_params = %{email: email, message: message, name: name}

    Contacts.create_contact(contact_params)
    # new_email()
    # |> from("#{email}")
    # |> to("efratzaror2014@gmail.com")
    # |> subject("הודעה חדשה מ #{name}")
    # |> html_body("<style>html: {direction: rtl; } </style>#{message}")
    # |> text_body("#{message}")
  end
end
