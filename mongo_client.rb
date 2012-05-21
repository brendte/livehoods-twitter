require 'uri'
require 'mongo_client'

class MongoClient

  ENV['MONGOLAB_URI'] ||= 'mongodb://heroku_app4504006:a9cotq6m6dg4llvm3iut5hglag@ds033157.mongolab.com:33157/heroku_app4504006'

  def initialize(collection)
    uri  = ENV['MONGOLAB_URI']
    parsed_uri = URI.parse(uri)
    @conn = Mongo::Connection.from_uri(uri, :pool_size => 5, :pool_timeout => 5)
    @db = @conn.db(parsed_uri.path.gsub(/^\//, ''))
    @collection = @db.collection(collection)
  end

  attr_accessor :collection
end

