defmodule Accountkit.Auth.Email do
  @moduledoc """
  Email normalization for auth flows. Format validation lives on form changesets.
  """

  @doc """
  Trims whitespace and lowercases the email.
  """
  def normalize(email) do
    email
    |> to_string()
    |> String.trim()
    |> String.downcase()
  end
end
