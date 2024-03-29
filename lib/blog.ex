defmodule Blog do
  require Logger

  def assets do
    File.cp_r("assets/static/", "output/")
    File.cp("output/css/app.css", "output/css/app-#{file_hash_short("output/css/app.css")}.css")

    Logger.debug(file_hash("output/js/analytics.js"))

    File.cp(
      "output/js/analytics.js",
      "output/js/analytics-#{file_hash_short("output/js/analytics.js")}.js"
    )

    File.cp(
      "output/js/highlight.js",
      "output/js/highlight-#{file_hash_short("output/js/highlight.js")}.js"
    )
  end

  defp file_hash_short(path) do
    hash_ref = :crypto.hash_init(:md5)

    File.stream!(path)
    |> Enum.reduce(hash_ref, fn chunk, prev_ref ->
      new_ref = :crypto.hash_update(prev_ref, chunk)
      new_ref
    end)
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end

  defp file_hash(path) do
    hash_ref = :crypto.hash_init(:sha384)

    File.stream!(path)
    |> Enum.reduce(hash_ref, fn chunk, prev_ref ->
      new_ref = :crypto.hash_update(prev_ref, chunk)
      new_ref
    end)
    |> :crypto.hash_final()
    |> Base.encode64()
  end

  def html do
    all_pages = File.ls!("content") |> Enum.sort() |> Enum.reverse()

    others =
      all_pages
      |> Enum.reduce([], fn path, acc ->
        page = Post.from_file("content/#{path}")

        html =
          Phoenix.View.render_to_string(
            Blog.Views.Page,
            "show.html",
            page
            |> Map.merge(%{
              css_integrity: "sha384-#{file_hash("output/css/app.css")}",
              css: "/css/app-#{file_hash_short("output/css/app.css")}.css",
              analytics_integrity: "sha384-#{file_hash("output/js/analytics.js")}",
              analytics: "/js/analytics-#{file_hash_short("output/js/analytics.js")}.js",
              highlight_integrity: "sha384-#{file_hash("output/js/highlight.js")}",
              highlight: "/js/highlight-#{file_hash_short("output/js/highlight.js")}.js",
              layout: {Blog.Views.Layout, "layout.html"},
              other_pages: []
            })
            |> Map.from_struct()
          )

        File.mkdir_p("output/post/#{page.slug}")
        File.write("output/post/#{page.slug}/index.html", html)

        acc ++
          [
            %{
              title: page.title,
              slug: page.slug,
              published: page.published,
              revised: page.revised
            }
          ]
      end)

    [homepage | _] = all_pages
    homepage = Post.from_file("content/#{homepage}")
    [_ | others] = others

    File.write("output/sitemap.xml", Sitemap.build(others))

    html =
      Phoenix.View.render_to_string(
        Blog.Views.Page,
        "show.html",
        homepage
        |> Map.merge(%{
          css_integrity: "sha384-#{file_hash("output/css/app.css")}",
          css: "/css/app-#{file_hash_short("output/css/app.css")}.css",
          analytics_integrity: "sha384-#{file_hash("output/js/analytics.js")}",
          analytics: "/js/analytics-#{file_hash_short("output/js/analytics.js")}.js",
          highlight_integrity: "sha384-#{file_hash("output/js/highlight.js")}",
          highlight: "/js/highlight-#{file_hash_short("output/js/highlight.js")}.js",
          layout: {Blog.Views.Layout, "layout.html"},
          other_pages: others
        })
        |> Map.from_struct()
      )

    File.write("output/index.html", html)
  end
end
