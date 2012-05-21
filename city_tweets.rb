require_relative 'mongo_client'

class CityTweets

  def initialize(city_name)
    @city_name = city_name
    @mongo_client = MongoClient.new(@city_name.downcase + '_tweets')
  end

end