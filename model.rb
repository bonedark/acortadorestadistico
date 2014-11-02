class Shortenedurl
<<<<<<< HEAD
    include DataMapper::Resource
    
    property :id, Serial
    property :uid, String
    property :email, String
    property :url, Text
    property :urlshort, Text, :key => true
    
end
=======
  include DataMapper::Resource

  property :id, Serial
  property :uid, String
  property :email, String
  property :url, Text
  property :urlshort, Text, :key => true

end

>>>>>>> desarrollo
