defmodule AccountkitWeb.Features.Auth.LoginForm do
  @moduledoc """
  Schemaless changeset for the magic-link sign-in form.
  """
  import Ecto.Changeset

  alias Accountkit.Auth.Email

  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @types %{email: :string}

  def changeset(params \\ %{}, opts \\ []) do
    {%{}, @types}
    |> cast(params, [:email])
    |> update_change(:email, &normalize_field/1)
    |> validate_required([:email], message: "Enter your email address.")
    |> validate_format(:email, @email_format, message: "Enter a valid email address.")
    |> put_form_action(opts[:action])
  end

  defp put_form_action(changeset, nil), do: changeset
  defp put_form_action(changeset, action), do: %{changeset | action: action}

  defp normalize_field(value), do: Email.normalize(value)
end
