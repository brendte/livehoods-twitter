require 'rubygems'
require 'bundler/setup'
require 'mongo'
require 'aws-sdk'
require 'json'
require 'time'
require 'uri'

require_relative 'twitter_stream'

EM.threadpool_size = 10

EM.run do

  ##dev
  #@test_file = File.open('tweet_test_file', 'w+')
  ##production
  #@dynamo_db = AWS::DynamoDB.new(:access_key_id => ENV['S3_ACCESS_KEY_ID'], :secret_access_key => ENV['S3_SECRET_ACCESS_KEY'])
  #@table = @dynamo_db.tables['tweets_philadelphia']
  #@table.hash_key = { :user_id => :number }
  #@table.range_key = { :created_at => :number }

  #MongoDB
  ENV['MONGOLAB_URI'] ||= 'mongodb://heroku_app4504006:a9cotq6m6dg4llvm3iut5hglag@ds033157.mongolab.com:33157/heroku_app4504006'
  uri  = ENV['MONGOLAB_URI']
  parsed_uri = URI.parse(uri)
  @conn = Mongo::Connection.from_uri(uri, :pool_size => 5, :pool_timeout => 5)
  @db = @conn.db(parsed_uri.path.gsub(/^\//, ''))
  @collection = @db.collection('philly_tweets_2')
  @count = 0
  philly = [-75.280327,39.864841,-74.941788,40.154541]
  stream = TwitterStream.new(philly)

  def tweet_count
    puts "\n>>>>>>>>>>>>>>>>>>>>> TWEET COUNT: #@count <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
  end

  def record_count
    puts "\n>>>>>>>>>>>>>>>>>>>>> RECORD COUNT: #{@table.items.count} <<<<<<<<<<<<<<<<<<<<<<<<<<\n"
  end

  #MongoDB
  def write_to_mongo(tweet)
    EM.defer do
      hash_for_mongo = build_dynamo_hash(tweet)
      @collection.insert(hash_for_mongo) unless hash_for_mongo.nil?
    end
  end

  ##prod
  #def write_to_dynamo(tweet)
  #  EM.defer do
  #    @table.items.create(build_dynamo_hash(tweet))
  #  end
  #end

  ##dev
  #def write_to_file(tweet)
  #  EM.defer do
  #    @test_file.write(build_dynamo_hash(tweet))
  #  end
  #end

  def build_dynamo_hash(tweet)
    parsed_tweet = JSON.parse(tweet)
    if parsed_tweet['geo'].nil?
      log_no_geo(parsed_tweet)
      nil
    else
      log_tweet(parsed_tweet)
      {
        :user_id => parsed_tweet['user']['id'].to_i,
        :created_at => Time.parse(parsed_tweet['created_at']).to_i,
        :full_tweet => parsed_tweet
      }
    end
  end

  def bump_count
    @count += 1
  end

  def log_tweet(parsed_tweet)
    puts "#{parsed_tweet['id']}"
  end

  def log_no_geo(parsed_tweet)
    puts "Geo is nil: #{log_tweet(parsed_tweet)}"
  end

  #MongoDB
  stream.ontweet do |tweet|
    write_to_mongo(tweet)
    bump_count
  end

  ##production
  #stream.ontweet do |tweet|
  #  write_to_dynamo(tweet)
  #  bump_count
  #end

  ##dev
  #stream.ontweet do |tweet|
  #  puts tweet
  #  write_to_file(tweet)
  #  bump_count
  #end

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
    #record_count
  end

end