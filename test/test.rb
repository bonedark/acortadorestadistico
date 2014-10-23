ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative '../twitter.rb'


include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "SYTW P2 - page" do
    
    
    it "Should return index" do
        get '/'
        assert last_response.ok?
    end
    
    it "should return title" do
        get '/'
        assert_match "<title>SYTW - P2 - Amigos Populares en Twitter</title>", last_response.body
    end
    
    it "should return form" do
        get '/'
        assert_match "<p ><b>Introduzca su nombre en Twitter: </b></p>", last_response.body
        assert_match "<p ><b>¿Cuántos seguidores desea ver? </b></p>", last_response.body
    end


    it "Debe cargar la imagen del pajarito" do
	get '/'
	assert_match '<img src="/bird_icon.png" WIDTH=100 HEIGHT=100 />', last_response.body
    end

    it "should return foot" do
        get '/'
        assert_match "<p><b>SYTW - Práctica 2 Realizada por:</b><h1>-> Daniel Nicolás Fernández del Castillo Salazar</h1><h1>-> Jonathan Barrera Delgado</h1></p>", last_response.body
    end
    
    #it "test_styles"
    #    get "/public/css/estilo.css"
    #   assert last_response.ok?
    #end
end

describe "SYTW P2 - Funtions" do
    before :all do
        @tw = Twitterpopular.new
        @client = my_twitter_client()
        @name1 = "b0nedark"
        @name2 = "bosdadanedark"
    end
    
    it "the user exist" do
        assert @tw.dusuario(@client,@name1)
    end
    
    it "the user not exist" do
        refute @tw.dusuario(@client, @name2)
    end
end
