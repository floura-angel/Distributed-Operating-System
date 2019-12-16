defmodule TwitterCloneWeb.PageController do
  use TwitterCloneWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
