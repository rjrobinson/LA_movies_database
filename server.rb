require 'pg'
require 'sinatra'
require 'pry'


############################
          # METHODS
############################


def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end


############################
          # ROUTES
############################


get '/' do
  redirect '/movies'
end

get '/actors' do
  query = 'SELECT * FROM actors ORDER BY actors.name LIMIT 10;'

  @actors = db_connection do |conn|
      conn.exec(query)
    end

  erb :'actors/index'
end

get '/actors/:id' do
  selected = params[:id]
  query = '
    SELECT actors.name AS actor, movies.title AS title, cast_members.character AS role, movies.id AS movie_id FROM cast_members
    JOIN movies ON movies.id = cast_members.movie_id
    JOIN actors ON actors.id = cast_members.actor_id
    WHERE actors.id = $1
    ORDER BY movies.title;
    '
    @actor = db_connection do |conn|
      conn.exec_params(query, [selected])
    end
  erb :'actors/show'
end

get '/movies' do
  query = '
    SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT OUTER JOIN studios ON movies.studio_id = studios.id
    JOIN genres ON movies.genre_id = genres.id
    ORDER BY movies.title LIMIT 20;
    '

  @movies = db_connection do |conn|
      conn.exec(query)
    end
      erb :'movies/index'
end

get '/movies/:id' do
  selected = params[:id]

  query_movies = '
    SELECT movies.title AS title, genres.name AS genre, studios.name AS studio FROM movies
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = $1;
    '
  query_actors = '
    SELECT actors.id AS id, actors.name AS actor, cast_members.character AS role FROM actors
    JOIN cast_members ON actors.id = cast_members.actor_id
    LEFT OUTER JOIN movies ON movies.id = cast_members.movie_id
    WHERE movies.id = $1;
  '
  @movie = db_connection do |conn|
    conn.exec_params(query_movies, [selected])
  end
  @actors = db_connection do |conn|
    conn.exec_params(query_actors, [selected])
  end

  erb :'movies/show'
end

