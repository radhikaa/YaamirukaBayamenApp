class SambavamsController < ApplicationController
  before_action :set_locations, only: [:plot, :safe_routes]

  def new
    @location = params[:current_location]
  end

  def index
  end

  def create
    
  end

  def plot
    render json: @locations, status: :ok
  end

  def safe_routes
    crisis_locations = locations(@locations)
    paths = []
    routes_json = routes_from_maps(request_url)
    p "routes_json", routes_json["routes"].size
    routes_json["routes"].each do |route|
      path = construct_path(route)
      path = traverse_route(route, path, crisis_locations)
      paths << path
    end
    p paths
    safe_routes = categorised_routes(paths)
    route_bounds = []
    safe_routes.each do |safe_route|
      route_bounds << {"bounds" => [{"lat" => safe_route.bounds[0]["lat"], "lng" => safe_route.bounds[0]["lng"]},
                                    {"lat" => safe_route.bounds[1]["lat"], "lng" => safe_route.bounds[1]["lng"]}]
      }
    end
    render json: route_bounds, status: :ok
  end

  private
  def set_locations
    params = '{"query":"*","docs":"100"}'
    user = 'radhikab@thoughtworks.com'
    password = 'radhikab'
    user_id = '1201'
    fetch_url = "https://api-eu.clusterpoint.com/#{user_id}/YaamirukaBayamen/_search.json"
    @locations = locations_from_cluster(params, fetch_url, user, password)
  end

  def locations_from_cluster(payload, cluster_url, username, password)
    resource = RestClient::Resource.new(cluster_url, user: username, password: password)
    response = resource.post(payload)
    response.body
  end

  def locations(locations_json)
    locations = []
    locations_json = JSON.parse(locations_json)
    locations_json["documents"].each do |location|
      locations << Location.new(name: location["name"], latitude: location["lat"].to_f, longitude: location["long"].to_f, occurences: location["occurences"].to_i)
    end if locations_json["documents"].present?
    locations
  end

  def init_safe_route_path
    origin = 'Alandur,IN'
    destination = 'Adyar,IN'
    [origin, destination]
  end

  def request_url
    api_key = 'AIzaSyAYU_fYcPQGp1FnLfH4W0F07hofMQkvZcQ'
    origin, destination = init_safe_route_path
    alternative_routes = true
    "https://maps.googleapis.com/maps/api/directions/json?origin=#{origin}&destination=#{destination}&alternatives=#{alternative_routes}&key=#{api_key}"
  end

  def routes_from_maps(url)
    resource = RestClient::Resource.new(url)
    response = resource.get
    JSON.parse(response.body)
  end

  def construct_path(route)
    origin, destination = init_safe_route_path
    ne_bound = route["bounds"]["northeast"]
    sw_bound = route["bounds"]["southwest"]
    Path.new(start_point: origin, end_point: destination, occurences: 0, unsafe_measure: 0, bounds: [ne_bound, sw_bound])
  end

  def update_path(crisis_locations, path, latitude, longitude)
    matching_crisis_locations = crisis_locations.select { |loc| loc.latitude == latitude && loc.longitude == longitude }
    if matching_crisis_locations.present?
      path.occurences += 1
      path.unsafe_measure += matching_crisis_locations.first.occurences.to_i
    end
    path
  end

  def traverse_route(route, path, crisis_locations)
    points = []
    route["legs"].each do |leg|
      leg["steps"].each do |step|
        start_point_lat = step["start_location"]["lat"]
        start_point_long = step["start_location"]["lng"]
        path = update_path(crisis_locations, path, start_point_lat, start_point_long) unless points.include?([start_point_lat,start_point_long])
        points << [start_point_lat, start_point_long]
        end_point_lat = step["end_location"]["lat"]
        end_point_long = step["end_location"]["lng"]
        path = update_path(crisis_locations, path, end_point_lat, end_point_long) unless points.include?([end_point_lat,end_point_long])
        points << [end_point_lat, end_point_long]
      end
    end
    path
  end

  def categorised_routes(paths)
    minimum_occurrence = paths.collect(&:occurences).min
    minimum_unsafe_measure = paths.collect(&:unsafe_measure).min
    min_occurrence_route = paths.select {|path| path.occurences == minimum_occurrence}.first
    min_unsafe_route = paths.select {|path| path.unsafe_measure == minimum_unsafe_measure}.first
    [min_occurrence_route,min_unsafe_route]
  end
end