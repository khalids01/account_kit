defmodule AccountkitWeb.PageController do
  use AccountkitWeb, :controller

  def home(conn, _params) do
    render(conn, :home, current_scope: current_scope(conn))
  end

  defp current_scope(conn) do
    case conn.assigns[:current_user] do
      %{__struct__: _} = user -> %{user: user}
      _ -> nil
    end
  end
end
