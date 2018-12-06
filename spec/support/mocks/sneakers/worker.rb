module Sneakers
  module Worker
    extend ActiveSupport::Concern

    class_methods do
      def from_queue(*); end
    end

    def logger
      Rails.logger
    end
  end
end
