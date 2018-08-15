class XmlParser
  def self.parse(input)
    new(input).result
  end

  def initialize(input)
    @input = input
  end

  def result
    @result ||= Hash.from_xml(@input)
  end
end
