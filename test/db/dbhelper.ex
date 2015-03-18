defmodule Ecto.Subscribe.Test.DbHelper do
  def create_mysql_db do
    :os.cmd 'mysql -u root -e "CREATE DATABASE IF NOT EXISTS ecto_subscribe_test;"'
  end

  def drop_mysql_db do
    :os.cmd 'mysql -u root -e "DROP DATABASE IF EXISTS ecto_subscribe_test;"'
  end

  def create_pg_db do
    :os.cmd 'psql -U postgres -c "CREATE DATABASE ecto_subscribe_test;"'
  end

  def drop_pg_db do
    :os.cmd 'psql -U postgres -c "DROP DATABASE ecto_subscribe_test;"'
  end

  def drop_db do
    case Mix.env do
      :pg ->
        drop_pg_db
      _ ->
        drop_mysql_db
    end
  end

  def create_db do
    case Mix.env do
      :pg ->
        create_pg_db
      _ ->
        create_mysql_db
    end
  end
end
