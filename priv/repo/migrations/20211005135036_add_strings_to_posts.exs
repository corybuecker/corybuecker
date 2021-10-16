defmodule Blog.Repo.Migrations.AddStringsToPosts do
  use Ecto.Migration

  def change do
    alter table(:pages) do
      add :description, :string, null: false
      add :title, :string, null: false
    end
  end
end
