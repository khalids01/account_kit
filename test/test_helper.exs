ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Accountkit.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:hammer)
