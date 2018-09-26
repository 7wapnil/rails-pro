module Mts
  class SingleSession
    include Singleton

    def session(config = nil)
      @session ||= Mts::Session.new(config)
    end
  end
end
