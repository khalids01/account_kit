defmodule AccountkitWeb.Auth.LoginForm do
  @moduledoc """
  Schemaless changeset for the magic-link sign-in form.
  """
  import Ecto.Changeset

  alias Accountkit.Auth.Email

  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @types %{email: :string}

  def changeset(params \\ %{}) do
    {%{}, @types}
    |> cast(params, [:email])
    |> update_change(:email, &normalize_field/1)
    |> validate_required([:email], message: "Enter your email address.")
    |> validate_format(:email, @email_format, message: "Enter a valid email address.")
  end

  defp normalize_field(value), do: Email.normalize(value)
end
