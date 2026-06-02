defmodule AccountkitWeb.Features.EndUsers.Actions do
  alias Accountkit.Accounts.EndUser
  alias Accountkit.Repo
  alias AccountkitWeb.Features.EndUsers.Queries

  require Ecto.Query

  def run(actor, id, action) when action in [:ban, :archive] do
    with {:ok, end_user} <- Queries.get_scoped(id, actor),
         {:ok, end_user} <- update(end_user, action, actor),
         {_, _} <- revoke_tokens(end_user) do
      {:ok, end_user}
    end
  end

  def run(actor, id, action) when action in [:unban, :restore] do
    with {:ok, end_user} <- Queries.get_scoped(id, actor) do
      update(end_user, action, actor)
    end
  end

  def run(actor, id, :delete) do
    with {:ok, %{archived_at: %DateTime{}} = end_user} <- Queries.get_scoped(id, actor),
         {_, _} <- revoke_tokens(end_user),
         :ok <- destroy(end_user, actor) do
      {:ok, end_user}
    else
      {:ok, %EndUser{}} -> {:error, :not_archived}
      error -> error
    end
  end

  def run(actor, id, :update_profile, attrs) do
    with {:ok, end_user} <- Queries.get_scoped(id, actor) do
      update(end_user, :update_profile, attrs, actor)
    end
  end

  def bulk(actor, ids, action) when is_list(ids) do
    ids
    |> Enum.uniq()
    |> Enum.reduce(%{ok: [], error: []}, fn id, acc ->
      case run(actor, id, action) do
        {:ok, end_user} -> %{acc | ok: [end_user | acc.ok]}
        _error -> %{acc | error: [id | acc.error]}
      end
    end)
    |> then(&%{&1 | ok: Enum.reverse(&1.ok), error: Enum.reverse(&1.error)})
  end

  defp update(end_user, action, actor) do
    end_user
    |> Ash.Changeset.for_update(action, %{}, actor: actor)
    |> Ash.update()
  end

  defp update(end_user, action, attrs, actor) do
    end_user
    |> Ash.Changeset.for_update(action, attrs, actor: actor)
    |> Ash.update()
  end

  defp destroy(end_user, actor) do
    end_user
    |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
    |> Ash.destroy()
    |> case do
      :ok -> :ok
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp revoke_tokens(end_user) do
    subject = AshAuthentication.user_to_subject(end_user)

    Repo.delete_all(
      Ecto.Query.from(token in "end_user_tokens",
        where: token.subject == ^subject
      )
    )
  end
end
