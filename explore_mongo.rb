require 'rubygems'
require 'pry'
require 'mongo'
require 'json'
require 'uri'

mongo_uri  = ENV['MONGOLAB_URI']
mongo_parsed_uri = URI.parse(mongo_uri)
conn = Mongo::Connection.from_uri(mongo_uri, :pool_size => 5, :pool_timeout => 5)
db = conn.db(mongo_parsed_uri.path.gsub(/^\//, ''))
@mongo_collection = db.collection('philly_tweets_2')
@mongo_collection_bad = db.collection('philly_tweets')

binding.pry


