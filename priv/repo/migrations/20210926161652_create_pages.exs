defmodule Blog.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :slug, :string
      add :body, :text

      timestamps()
    end
  end
end
