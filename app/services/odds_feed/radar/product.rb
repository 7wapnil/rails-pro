module OddsFeed
  module Radar
    class Product
      PRODUCT_LIVE = 1
      PRODUCT_PRE_MATCH = 3

      def self.available_product_ids
        [PRODUCT_LIVE, PRODUCT_PRE_MATCH]
      end

      def initialize(id)
        @id = id
      end

      def live?
        @id == PRODUCT_LIVE
      end
    end
  end
end
