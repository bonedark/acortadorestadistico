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
require 'chartkick'
%w( dm-core dm-timestamps dm-types restclient xmlsimple).each  { |lib| require lib}

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

#Get's para estadísticas y filtrado de usuarios en estadisticas
['/all/stadistic', '/all/stadistic/:user'].each do |path|
    get path do
        if params[:user] == 'public'
            @short_url = Shortenedurl.all(:email => nil, :order => [:n_visits.desc])
            elsif params[:user] != nil
            @short_url = Shortenedurl.all(:email => params[:user], :order => [:n_visits.desc])
            else
            @short_url = Shortenedurl.all(:order => [:n_visits.desc])
        end
        haml :estadisticas, :layout => :admin
    end
end

#Get's para info por URL
['/info/:short_url', '/info/:short_url/:num_of_days', '/info/:short_url/:num_of_days/:map'].each do |path|
    get path do
        @link = Shortenedurl.first(:urlshort => params[:short_url])
        @visit = Visit.all()
        @country = Hash.new
        @visit.count_by_country_with(params[:short_url]).to_a.each do |item|
            @country[item.country] = item.count
        end
        @days = Hash.new
        @visit.as_date(params[:short_url]).each do |item|
            @days[item.date] = item.count
        end
        @str = map(@visit)
        haml :info, :layout => :admin
    end
end

#Fin de: dependencias de info

#Get para visitar una URL corta
get '/visitar/:shortened' do
    puts "inside get '/:shortened': #{params}"
    short_url = Shortenedurl.first(:urlshort => params[:shortened])
    short_url.n_visits += 1
    short_url.save
    data = get_geo
    visit = Visit.new(:ip => data['ip'], :country => data['countryName'], :countryCode => data['countryCode'], :city => data["city"], :latitude => data["latitude"], :longitude => data["longitude"], :shortenedurl => short_url, :created_at => Time.now)
    visit.save
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
                @short_url = Shortenedurl.first_or_create(:uid => session[:uid], :email => session[:email], :url => params[:url], :urlshort => sh, :n_visits => 0)
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

#Funciones para obtener IP, Geolocalizacion y contruir el mapa con la API
def get_remote_ip(env)
    puts "request.url = #{request.url}"
    puts "request.ip = #{request.ip}"
    puts env
    if addr = env['HTTP_X_FORWARDED_FOR']
        puts "env['HTTP_X_FORWARDED_FOR'] = #{addr}"
        addr.split(',').first.strip
        else
        puts "env['REMOTE_ADDR'] = #{env['REMOTE_ADDR']}"
        env['REMOTE_ADDR']
    end
end

def get_geo
    xml = RestClient.get "http://freegeoip.net/xml/#{get_remote_ip(env)}"
    data = XmlSimple.xml_in(xml.to_s)
    {"ip" => data['Ip'][0].to_s, "countryCode" => data['CountryCode'][0].to_s, "countryName" => data['CountryName'][0].to_s, "city" => data['City'][0].to_s, "latitude" => data['Latitude'][0].to_s, "longitude" => data['Longitude'][0].to_s}
end


def map(visit)
    str = ''
    visit.as_map(params[:short_url]).each do |item|
        if (item.latitude != nil)
            item.city = (item.city == '{}') ? item.country : item.city
            str += "var pos = new google.maps.LatLng(#{item.latitude},#{item.longitude});
            
            var infowindow = new google.maps.InfoWindow({
                                                        map: map,
                                                        position: pos,
                                                        content: \" #{item.city}: #{item.count} \"
                                                        });
                                                        map.setCenter(pos);"
        end
    end
    str
end
#Get's y funciones de debug
get '/debug/visitado' do
    puts "inside get '/': #{params}"
    @list = Shortenedurl.visits.all()
    puts @list
    puts "-------------------------------------------"
    # in SQL => SELECT * FROM "Shortenedurl" ORDER BY "id" ASC
end