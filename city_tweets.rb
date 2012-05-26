require_relative 'mongo_client'

class CityTweets

  def initialize(city_name)
    @city_name = city_name
    @mongo_client = MongoClient.new(@city_name.downcase + '_tweets').collection
    #@mongo_client = MongoClient.new('philly_tweets_no_geo').collection
  end

  attr_reader :city_name

  def assign_to_grid_box(city_grid)
    #tweets_in_the_box = 0
    city_grid.grid.each do |box|
      @mongo_client.update({'full_tweet.coordinates.coordinates' => {'$within' => {'$box' => box['box']}}, 'my_box_id' => {'$exists' => false}}, {'$set' => {'my_box_id' => box['box_id']}}, {:multi => true})
      #num_tweets = @mongo_client.find('full_tweet.coordinates.coordinates' => {'$within' => {'$box' => box['box']}}).count
      #puts "Box: #{box['box']}, count: #{num_tweets}"
      #tweets_in_the_box += num_tweets
    end
    #puts "Total tweets: #{tweets_in_the_box}"
  end

  def distinct_users
    @distinct_users ||= @mongo_client.distinct('full_tweet.user.id')
  end

  def user_ids_tweets_in_grid_box(city_grid)
    @mongo_client.find('my_box_id' => city_grid)
  end

end