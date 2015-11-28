namespace :clusterpoint do
  task save_sambavams: :environment do
    location = {location_name: "Koyambedu", lat: "13.072", long: "18.201"}
    location = Location.new_from_hash(location)
    location.save
    sambavam = Sambavam.new_from_hash({location: location, occurences: 10})
    sambavam.save
  end

end
