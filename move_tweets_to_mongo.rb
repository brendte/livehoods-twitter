require 'rubygems'
#require 'bundler/setup'
require 'mongo'
require 'aws-sdk'
require 'json'
require 'uri'
require 'redis'

ENV['MONGOLAB_URI'] # ||= 'mongodb://heroku_app4504006:a9cotq6m6dg4llvm3iut5hglag@ds033157.mongolab.com:33157/heroku_app4504006'
REDIS_URI = 'redis://redistogo:32fcda12c2bbfd9bf3673d3ea2653fc0@ray.redistogo.com:9039/'

def setup_clients
  mongo_uri  = ENV['MONGOLAB_URI']
  mongo_parsed_uri = URI.parse(mongo_uri)
  conn = Mongo::Connection.from_uri(mongo_uri, :pool_size => 5, :pool_timeout => 5)
  db = conn.db(mongo_parsed_uri.path.gsub(/^\//, ''))
  @mongo_collection = db.collection('philly_tweets_2')
  @mongo_collection_bad = db.collection('philly_tweets')

  dynamo_db = AWS::DynamoDB.new(:access_key_id => ENV['S3_ACCESS_KEY_ID'], :secret_access_key => ENV['S3_SECRET_ACCESS_KEY'])
  @dynamo_table = dynamo_db.tables['tweets_philadelphia']
  @dynamo_table.hash_key = { :user_id => :number }
  @dynamo_table.range_key = { :created_at => :number }

  redis_uri = REDIS_URI
  redis_parsed_uri = URI.parse(redis_uri)
  @redis_client = Redis.new(:host => redis_parsed_uri.host, :port => redis_parsed_uri.port, :password => redis_parsed_uri.password)
end

def write_to_mongo(dynamo_hash)
  @mongo_collection.insert(dynamo_hash)
end


setup_clients

#@redis_client.pipelined do
#  File.open('dynamo_dump') do |file|
#    while line = file.gets do
#      arg_array = line.split(',')
#      arg_hash = {:user_id => arg_array[0].to_i, :created_at => arg_array[1].to_i}
#      @redis_client.lpush(:dynamo_keys, JSON.generate(arg_hash))
#    end
#  end
#end
#while next_args = @redis_client.lpop(:dynamo_keys)
#  dynamo_args = JSON.parse(next_args)
#  item = @dynamo_table.items[dynamo_args['user_id'], dynamo_args['created_at']]
#  orig_hash = item.attributes.to_h
#  orig_hash['user_id'] = orig_hash['user_id'].to_i
#  orig_hash['created_at'] = orig_hash['created_at'].to_i
#  orig_hash['full_tweet'] = JSON.parse(orig_hash['full_tweet'])
#  write_to_mongo(orig_hash)
#end

full_coll_cursor = @mongo_collection_bad.find
count = 0
full_coll_cursor.each do |orig_hash|

  if orig_hash['full_tweet'].kind_of? BSON::OrderedHash
    new_hash = {}
    new_hash['user_id'] = orig_hash['user_id']
    new_hash['created_at'] = orig_hash['created_at']
    new_hash['full_tweet'] = orig_hash['full_tweet']
    puts write_to_mongo(new_hash)
  end
end

puts count
