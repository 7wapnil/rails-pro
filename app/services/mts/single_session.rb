module Mts
  class SingleSession
    include Singleton

    def session(config = nil)
      @session ||= Mts::Session.new(config)
    end

    private_class_method :new
  end
end
