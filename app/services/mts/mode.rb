module Mts
  class Mode
    def self.production?
      ENV['MTS_MODE'] == 'production'
    end
  end
end
