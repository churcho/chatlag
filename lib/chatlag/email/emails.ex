defmodule Chatlag.Emails do
  import Bamboo.Email

  # efratzaror2014
  def contact_email(%{email: email, message: message, name: name}) do
    message = message |> String.replace(~r/\n/, "<br>", global: true)

    new_email()
    |> from("#{email}")
    |> to("efratzaror2014@gmail.com")
    |> subject("הודעה חדשה מ #{name}")
    |> html_body("<style>html: {direction: rtl; } </style>#{message}")
    |> text_body("#{message}")
  end
end
