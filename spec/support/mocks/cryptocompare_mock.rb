module Cryptocompare
  module Price
    def self.find(from_sym, to_sym)
      { "#{from_sym}": { "#{to_sym}": 1 } }.as_json
    end
  end
end
