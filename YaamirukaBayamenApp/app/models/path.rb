class Path
  attr_accessor :start_point, :end_point, :occurences, :unsafe_measure, :bounds

  def initialize(options)
    self.start_point = options[:start_point]
    self.end_point = options[:end_point]
    self.bounds = options[:bounds]
    self.occurences = options[:occurences]
    self.unsafe_measure = options[:unsafe_measure]
  end
end