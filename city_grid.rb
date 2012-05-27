require_relative 'mongo_client'

class CityGrid
  @miles_in_degree_lat = 69.11

  def initialize(city_name = 'Philadelphia', bounding_box = [-75.280327,39.864841,-74.941788,40.154541], side_length_miles = 0.1)
    @city_name = city_name
    @side_length_miles = side_length_miles
    @bb = bounding_box
    @ne_lat_deg = @bb[3]
    @ne_lng_deg = @bb[2]
    @sw_lat_deg = @bb[1]
    @sw_lng_deg = @bb[0]
    @mongo_client = MongoClient.new(@city_name.downcase + '_grid').collection
    #@mongo_client = MongoClient.new('philadelphia_grid_test').collection
  end

  class << self
    attr_reader :miles_in_degree_lat
  end

  attr_reader :city_name, :ne_lat_deg, :ne_lng_deg, :sw_lat_deg, :sw_lng_rad, :bb

  def miles_in_degree_lng(lat)
    Math.cos(deg_to_rad(lat)) * CityGrid.miles_in_degree_lat
  end

  def gridify
    current_lat = @sw_lat_deg
    current_lng = @sw_lng_deg
    counter = 0
    while current_lat <= @ne_lat_deg + lat_degrees_to_add
      next_lat = current_lat + lat_degrees_to_add
      while current_lng <= @ne_lng_deg + lng_degrees_to_add(current_lat)
        counter += 1
        next_lng = current_lng + lng_degrees_to_add(current_lat)
        box = { :box_id => counter, :box => [[current_lng, current_lat], [next_lng, next_lat]] }
        @mongo_client.insert(box)
        current_lng = next_lng
      end
      current_lng = @sw_lng_deg
      current_lat = next_lat
    end
  end

  def grid
    @mongo_client.find
  end

  def box_ids
    @mongo_client.find({}, :fields => ['box_id'])
  end

  def box_ids_array
    @box_ids_array ||= create_box_ids_array
  end

  def update_record(selector, data)
    @mongo_client.update(selector, {'$set' => data})
  end

  def create_box_ids_array
    bida = []
    bids = box_ids
    bids.each {|bid| bida << bid['box_id']}
    bida
  end

  #private

  def ne_lat_rad
    deg_to_rad(@ne_lat_deg)
  end

  def ne_lng_rad
    deg_to_rad(@ne_lng_deg)
  end

  def sw_lat_rad
    deg_to_rad(@sw_lat_deg)
  end

  def sw_lng_rad
    deg_to_rad(@sw_lng_rad)
  end

  def deg_to_rad(deg)
    deg * Math::PI / 180.0
  end

  def rad_to_deg(rad)
    rad * 180.0 / Math::PI
  end

  def lng_degrees_to_add(lat)
    @side_length_miles / miles_in_degree_lng(lat)
  end

  def lat_degrees_to_add
    @side_length_miles / CityGrid.miles_in_degree_lat
  end

end