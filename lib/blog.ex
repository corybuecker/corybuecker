defmodule Blog do
  require Logger

  def assets do
    File.cp_r("assets/static/", "output/")
    File.cp("output/css/app.css", "output/css/app-#{file_hash_short("output/css/app.css")}.css")
    Logger.debug(file_hash("output/js/app.js"))
    File.cp("output/js/app.js", "output/js/app-#{file_hash_short("output/js/app.js")}.js")
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

  def hello do
    File.ls!("content")
    |> Enum.each(fn content_path ->
      Logger.debug(content_path)
      {:ok, {frontmatter, body}} = parse_content_file("content/#{content_path}")

      html =
        Phoenix.View.render_to_string(Blog.Views.Page, "show.html", %{
          body: body,
          css_integrity: "sha384-#{file_hash("output/css/app.css")}",
          css: "/css/app-#{file_hash_short("output/css/app.css")}.css",
          js_integrity: "sha384-#{file_hash("output/js/app.js")}",
          js: "/js/app-#{file_hash_short("output/js/app.js")}.js",
          layout: {Blog.Views.Layout, "layout.html"},
          other_pages: [],
          published: frontmatter["published"],
          revised: frontmatter["revised"],
          title: frontmatter["title"]
        })

      File.mkdir_p("output/post/#{frontmatter["slug"]}")
      File.write("output/post/#{frontmatter["slug"]}/index.html", html)
    end)

    [homepage | other_pages] = File.ls!("content") |> Enum.sort() |> Enum.reverse()

    other_pages =
      other_pages
      |> Enum.map(fn path -> extract_frontmatter("content/#{path}") end)
      |> Enum.map(fn {:ok, frontmatter} -> frontmatter end)

    Logger.debug(other_pages)
    {:ok, {frontmatter, body}} = parse_content_file("content/#{homepage}")

    html =
      Phoenix.View.render_to_string(Blog.Views.Page, "show.html", %{
        body: body,
        css_integrity: "sha384-#{file_hash("output/css/app.css")}",
        css: "/css/app-#{file_hash_short("output/css/app.css")}.css",
        js_integrity: "sha384-#{file_hash("output/js/app.js")}",
        js: "/js/app-#{file_hash_short("output/js/app.js")}.js",
        layout: {Blog.Views.Layout, "layout.html"},
        other_pages: other_pages,
        published: frontmatter["published"] |> maybe_date(),
        revised: frontmatter["revised"] |> maybe_date(),
        title: frontmatter["title"]
      })

    File.write("output/index.html", html)
  end

  defp parse_content_file(path) when is_bitstring(path) do
    Logger.debug(path)

    with {:ok, file_contents} <- File.read(path),
         [frontmatter_string, body_string] <-
           file_contents |> String.split("---", parts: 2, trim: true),
         {:ok, frontmatter} <- frontmatter_string |> YamlElixir.read_from_string(),
         {:ok, body, _} <- body_string |> Earmark.as_html(postprocessor: postprocessor()) do
      {:ok, {frontmatter, body}}
    else
      err -> err
    end
  end

  defp extract_frontmatter(path) when is_bitstring(path) do
    File.read!(path)
    |> String.split("---", parts: 2, trim: true)
    |> List.first()
    |> YamlElixir.read_from_string()
  end

  defp maybe_date(datetime) when is_bitstring(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _} -> dt |> DateTime.to_date()
      _ -> nil
    end
  end

  defp postprocessor() do
    fn
      {"a", attributes, body, map} ->
        {"a", attributes ++ [{"class", "underline hover:no-underline"}], body, map}

      {"h2", attributes, body, map} ->
        {"h2", attributes ++ [{"class", "text-2xl"}], body, map}

      {"h3", attributes, body, map} ->
        {"h3", attributes ++ [{"class", "text-xl"}], body, map}

      {tag, attributes, body, map} ->
        {tag, attributes, body, map}

      string ->
        string
    end
  end
end
