defmodule Accountkit.Accounts.User.Senders.SendMagicLinkEmail do
  @moduledoc """
  Sends a magic link email
  """

  use AshAuthentication.Sender
  use AccountkitWeb, :verified_routes

  import Swoosh.Email
  alias Accountkit.Mailer

  @impl true
  def send(user_or_email, token, _) do
    # if you get a user, its for a user that already exists.
    # if you get an email, then the user does not yet exist.

    email =
      case user_or_email do
        %{email: email} -> email
        email -> email
      end

    new()
    |> from({"AccountKit", "noreply@example.com"})
    |> to(to_string(email))
    |> subject("Your AccountKit magic link")
    |> html_body(body(token: token, email: email))
    |> Mailer.deliver!()
  end

  defp body(params) do
    # NOTE: You may have to change this to match your magic link acceptance URL.

    """
    <p>Hello, #{params[:email]}.</p>
    <p>Click this link to continue to AccountKit:</p>
    <p><a href="#{url(~p"/magic_link/#{params[:token]}")}">#{url(~p"/magic_link/#{params[:token]}")}</a></p>
    <p>If you did not request this link, you can ignore this email.</p>
    """
  end
end
