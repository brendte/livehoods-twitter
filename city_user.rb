require_relative 'mongo_client'

class CityUser

  def initialize(city_name)
    @city_name = city_name
    @mongo_client = MongoClient.new(@city_name.downcase + '_users').collection
  end

  attr_reader :city_name

  def collect_all(city_tweets)
    distinct_users = city_tweets.distinct_users
    next_id = @mongo_client.count
    distinct_users.each do |user_id|
      if @mongo_client.find('twitter_id' => user_id).count == 0
        @mongo_client.insert({'id' => next_id, 'twitter_id' => user_id})
        next_id += 1
      end
    end
  end

  def all_users_hash
    @all_users_hash ||= create_all_users_hash
  end

  def all_users
    @mongo_client.find
  end

  def create_all_users_hash
    auh = {}
    au = all_users
    au.each {|u| auh[u['twitter_id']] = u['id']}
    auh
  end

end
