require 'pry'

class CityGrid

  def initialize(city_name, bounding_box, side_length_meters = 160.9344)
    @city_name = city_name
    @side_length_meters = side_length_meters
    @bb = bounding_box
    @ne_lat_deg = @bb[3]
    @ne_lng_deg = @bb[2]
    @sw_lat_deg = @bb[1]
    @sw_lng_rad = @bb[0]
  end

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

  def meters_to_degrees_lng(meters, lat)
    Math.cos(lat)
  end

  def pry
    binding.pry
  end

end