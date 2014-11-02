#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
require 'data_mapper'
require 'omniauth-oauth2'
require 'omniauth-google-oauth2'


enable :sessions
set :session_secret, '*&(^#234a)'

configure :development do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/my_shortened_urls.db")
end

configure :production do
    DataMapper.setup(:default, ENV['DATABASE_URL'])
end

configure :test do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/test.db")
end

DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true

require_relative 'model'

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

#OmniAuth y get's de autenticación
use OmniAuth::Builder do
    config = YAML.load_file 'config/config.yml'
    provider :google_oauth2, config['identifier'], config['secret']
end

get '/auth/:name/callback' do
    @auth = request.env['omniauth.auth']
    session[:plt] = (params[:name] == 'google_oauth2') ? 'google' : params[:name]
    session[:uid] = @auth['uid'];
    session[:name] = @auth['info'].first_name + " " + @auth['info'].last_name
    session[:email] = @auth['info'].email
    @list = Shortenedurl.all(:uid => session[:uid])
    haml :user
end

get '/auth/logout' do
    session.clear
    redirect '/'
end
#Fin de: OmniAuth y get's de autenticación

#Get's /, errores
['/', '/:error'].each do |path|
    get path do
        if params[:error] == "ERROR"
            @message = "La url esta cogida"
            elsif params[:error] != nil
            @message =  "La url no existe"
            else
            @message = nil
        end
        if !session[:uid]
            puts "inside get '/': #{params}"
            @list = Shortenedurl.all(:order => [ :id.desc ], :limit => 20)
            haml :index
            else
            @list = Shortenedurl.all(:uid => session[:uid])
            haml :user
        end
    end
end


#Dependientes de info


#Fin de: dependencias de info

#Get para visitar una URL corta
get '/visitar/:shortened' do
    puts "inside get '/:shortened': #{params}"
    short_url = Shortenedurl.first(:urlshort => params[:shortened])
    short_url.save
    redirect short_url.url, 301
end

#Post para nuevas URL's
post '/' do
    @message = ""
    puts "inside post '/': #{params}"
    uri = URI::parse(params[:url])
    if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then
        if !Shortenedurl.first(:urlshort => params[:urlshort])
            begin
                sh = (params[:urlshort] != '') ? params[:urlshort] : (Shortenedurl.count+1)
                @short_url = Shortenedurl.first_or_create(:uid => session[:uid], :email => session[:email], :url => params[:url], :urlshort => sh)
                rescue Exception => e
                puts "EXCEPTION!!!!!!!!!!!!!!!!!!!"
                pp @short_url
                puts e.message
            end
            else
            @message = "ERROR"
            redirect "/#{@message}"
        end
        else
        logger.info "Error! <#{params[:url]}> está URL no es valida"
    end
    redirect '/'
end