require "sinatra"
require "pg"
require "pry"

set :bind, '0.0.0.0'  # bind to all interfaces

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

system 'psql movies < schema.sql'

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/" do
  erb :home_index
end

get "/actors" do
  sql = "SELECT id, name
         FROM actors
         ORDER BY substring(name, '([^[:space:]]+)(?:,|$)')"
  @all_actors = db_connection { |conn| conn.exec(sql) }.to_a

  erb :'actors/a_index'
end

get "/actors/:id" do
  @actor_id = params[:id].to_i

  sql = "SELECT cast_members.character, movies.title, movies.id
         FROM cast_members
         JOIN movies ON cast_members.movie_id = movies.id
         JOIN actors ON cast_members.actor_id = actors.id
         WHERE cast_members.actor_id = #{@actor_id}"

  @actor_info = db_connection { |conn| conn.exec(sql) }.to_a
  erb :'actors/a_show'
end

get "/movies" do
  sql = "SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS gname, studios.name AS sname
         FROM movies
         JOIN genres ON movies.genre_id = genres.id
         JOIN studios ON movies.studio_id = studios.id
         ORDER BY movies.title"

  @movies = db_connection { |conn| conn.exec(sql) }.to_a

  erb :'movies/m_index'
end

get "/movies/:id" do
  @movie_id = params[:id].to_i

  sql_m = "SELECT movies.id, movies.title, synopsis, genres.name AS gname, studios.name AS sname
           FROM movies
           JOIN genres ON movies.genre_id = genres.id
           JOIN studios ON movies.studio_id = studios.id
           WHERE movies.id = #{@movie_id}
           ORDER BY movies.title"

  sql_a = "SELECT movies.id, actors.id AS act_id, actors.name AS aname, cast_members.character
           FROM cast_members
           JOIN actors ON cast_members.actor_id = actors.id
           JOIN movies ON cast_members.movie_id = movies.id
           WHERE movies.id = #{@movie_id}
           ORDER BY actors.name"

  @movie_info = db_connection { |conn| conn.exec(sql_m) }.to_a
  @cast_info = db_connection { |conn| conn.exec(sql_a) }.to_a

  erb :'movies/m_show'
end
