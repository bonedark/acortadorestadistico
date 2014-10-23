class User
	include DataMapper::Resource
		property :id, Serial
		property :name, String
		property :email, String
		property :imagen, Text		
end

class ShortenedUrl
  include DataMapper::Resource

  property :id, Serial
  property :idusu, Text 
  property :url, Text
  property :to, Text
  
end
