defmodule Mix.Tasks.Build do
  use Mix.Task
  require Logger

  def run(_) do
    Logger.info(File.rm_rf("output") |> inspect())

    Mix.Task.run("tailwind", ["default"])
    Mix.Task.run("esbuild", ["default"])

    Blog.assets()
    Blog.html()
  end
end
