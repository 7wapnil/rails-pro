module Mts
  class Mode
    def self.production?
      ENV['MTS_MODE'] == 'production'
    end

    def self.stubbed?
      ENV['MTS_MODE'] == 'stub'
    end
  end
end
