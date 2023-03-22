defmodule Sitemap do
  import XmlBuilder

  def build(pages) when is_list(pages) do
    generate(
      {:urlset, [xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9"],
       [pages |> List.first() |> homepage_element()] ++ (pages |> Enum.map(&page_element/1))}
    )
  end

  defp homepage_element(page) do
    element(:url, %{}, [
      element(:loc, %{}, "https://corybuecker.com"),
      element(:lastmod, %{}, page.revised || page.published)
    ])
  end

  defp page_element(page) do
    element(:url, %{}, [
      element(:loc, %{}, "https://corybuecker.com/post/#{page.slug}"),
      element(:lastmod, %{}, page.revised || page.published)
    ])
  end
end
