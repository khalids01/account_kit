defmodule AccountkitWeb.Auth.RegisterForm do
  @moduledoc """
  Schemaless changeset for the magic-link sign-up form.
  """
  import Ecto.Changeset

  alias Accountkit.Auth.Email

  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @types %{name: :string, email: :string}

  def changeset(params \\ %{}) do
    {%{}, @types}
    |> cast(params, [:name, :email])
    |> update_change(:name, &trim_field/1)
    |> update_change(:email, &normalize_field/1)
    |> validate_required([:name], message: "Enter your name.")
    |> validate_required([:email], message: "Enter your email address.")
    |> validate_format(:email, @email_format, message: "Enter a valid email address.")
  end

  defp trim_field(value) when is_binary(value), do: String.trim(value)
  defp trim_field(value), do: value

  defp normalize_field(value), do: Email.normalize(value)
end
