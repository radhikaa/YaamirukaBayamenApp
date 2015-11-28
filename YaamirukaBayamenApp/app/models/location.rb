class Location
  attr_accessor :name, :latitude, :longitude, :occurences

  def initialize(options)
    self.name = options[:name]
    self.latitude = options[:latitude]
    self.longitude = options[:longitude]
    self.occurences = options[:occurences]
  end
end