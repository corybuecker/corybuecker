defmodule Blog.AdminFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blog.Admin` context.
  """

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        body: "some body",
        slug: "some slug"
      })
      |> Blog.create_page()

    page
  end
end
