defmodule BlogWeb.PageController do
  alias Blog.Page
  alias Blog.Repo
  import Ecto.Query, only: [{:order_by, 2}, {:first, 1}, {:limit, 2}, {:offset, 2}]
  use BlogWeb, :controller

  def index(conn, _params) do
    case Page |> order_by(desc: :published_at) |> first() |> Repo.one() do
      page = %Page{} ->
        render(conn, "show.html", %{page: page, pages: all_pages()})

      nil ->
        render(conn, BlogWeb.ErrorView, "404.html")
    end
  end

  def show(conn, params) do
    %{"slug" => slug} = params

    case Repo.get_by(Page, %{slug: slug}) do
      page = %Page{slug: ^slug} ->
        render(conn, "show.html", %{page: page, pages: []})

      nil ->
        render(conn, BlogWeb.ErrorView, "404.html")
    end
  end

  defp all_pages do
    case(Page |> order_by(desc: :published_at) |> limit(100) |> offset(1) |> Repo.all()) do
      pages when is_list(pages) -> pages
      nil -> []
    end
  end
end
