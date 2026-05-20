defmodule Accountkit.Repo do
  use Ecto.Repo,
    otp_app: :accountkit,
    adapter: Ecto.Adapters.Postgres
end
