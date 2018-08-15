class XmlParser
  def self.parse(input)
    new(input).parse
  end

  def initialize(input)
    @input = input
  end

  def parse
    @parsed ||= Hash.from_xml(@input)
  end
end
