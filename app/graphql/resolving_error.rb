class ResolvingError < GraphQL::Error
  attr_reader :errors_map

  def initialize(errors_map)
    @errors_map = errors_map
  end
end
