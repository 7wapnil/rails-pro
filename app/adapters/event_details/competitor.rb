module EventDetails
  class Competitor
    attr_reader :id, :name

    def initialize(id: nil, name: nil)
      @id = id
      @name = name
    end
  end
end
