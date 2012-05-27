#require 'pry'

require_relative 'city_grid'
require_relative 'city_tweets'
require_relative 'city_user'

philly_grid = CityGrid.new('Philadelphia', [-75.280327,39.864841,-74.941788,40.154541], 0.1)
#philly_grid.gridify
philly_tweets = CityTweets.new('Philadelphia')
#philly_tweets.assign_to_grid_box(philly_grid)
philly_users = CityUser.new('Philadelphia')

philly_grid.box_ids_array.each do |box_id|
  checkin_bag_hash = {}
  box_tweets = philly_tweets.user_ids_tweets_in_grid_box(box_id)
  box_tweets.each do |tweet|
    puts tweet
    checkin_bag_hash[philly_users.all_users_hash[tweet['user_id']].to_s] = checkin_bag_hash[philly_users.all_users_hash[tweet['user_id']]].to_i + 1
  end
  puts "Box id: #{box_id} has checkin_bag #{checkin_bag_hash}"
  philly_grid.update_record({:box_id => box_id}, {'check_in_bag' => checkin_bag_hash})
end


#binding.pry
