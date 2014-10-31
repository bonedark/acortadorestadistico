ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'sinatra'
require 'data_mapper'
require_relative '../app.rb'


include Rack::Test::Methods

def app
    Sinatra::Application
end

describe "SYTW P4 - page" do
    
    it "Should return index" do
        get '/'
        assert last_response.ok?
    end
    
end

describe "shortened urls" do
    
    before :all do
        @user = "pepito"
        @url = "http://www.github.com"
        @opcional = "git"
        @short_url = ShortenedUrl.first_or_create(:usuario => @user, :url => @url, :opcional => @opcional)
        @short_url1 = ShortenedUrl.first(:opcional => @opcional)
    end
    
    it "Should be in the bbdd" do
        assert @opcional, @short_url1.opcional
    end
    
    it "Should be the user" do
        assert 'pepito', @short_url1.usuario
    end
    
end