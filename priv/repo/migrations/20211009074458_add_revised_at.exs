defmodule Blog.Repo.Migrations.AddRevisedAt do
  use Ecto.Migration

  def change do
    alter table(:pages) do
      add :revised_at, :utc_datetime
    end
  end
end
