require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

require_relative 'twitter_stream'

dynamo_db = AWS::DynamoDB.new(:access_key_id => ENV['S3_ACCESS_KEY_ID'], :secret_access_key => ENV['S3_SECRET_ACCESS_KEY'])
table = dynamo_db.tables['tweets_philadelphia']
puts table.inspect
puts table.exists? ? "there" : "not there"
puts table.status
table.hash_key = { :user_id => :number }
table.range_key = { :created_at => :number }
puts table.schema_loaded?
#table.load_schema

def tweet_count
  puts "\n>>>>>>>>>>>>>>>>>>>>> TWEET COUNT: #@count <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
end

EM.threadpool_size = 10

EM.run do

  @count = 0
  philly = [-75.280327,39.864841,-74.941788,40.154541]
  stream = TwitterStream.new(philly)

  def write_to_dynamo(tweet)
    EM.defer do
      dynamo_hash = {
          :user_id => tweet[:user][:id],
          :created_at => tweet[:created_at],
          :full_tweet => tweet
      }
      table.items.create(dynamo_hash)
    end
  end

  stream.ontweet do |tweet|
    parsed_tweet = JSON.parse(tweet)
    #puts parsed_tweet
    write_to_dynamo(parsed_tweet)
    @count += 1
  end

  stream.on_disconnect do |_, _|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Disconnected at #{Time.now} <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    tweet_count
    $stdout.flush
  end

  stream.on_reconnect do |timeout, _|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Reconnecting in: #{timeout} seconds <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    $stdout.flush
  end

  stream.on_max_reconnects do |_, retries|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Failed after #{retries} failed reconnects <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    $stdout.flush
  end

  stream.on_connect_error do |response|
    $stdout.print "\n>>>>>>>>>>>>>>>>>>>>> Failed to connect with response code #{response} <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
    $stdout.flush
  end

  EM.add_periodic_timer(60) do
    tweet_count
  end

end