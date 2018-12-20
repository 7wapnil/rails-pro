module BonusDeactivation
  class BaseDeactivationStrategy < ApplicationService
    def initialize(customer_bonus, options = {})
      @customer_bonus = customer_bonus
      @options = options
    end

    def call
      deactivate
      log_deactivation
    end

    protected

    attr_accessor :customer_bonus, :options

    def deactivate
      msg = "#{self.class.name} needs to implement `#{__method__}` method!"
      raise NotImplementedError, msg
    end

    def log_deactivation
      # TODO: log deactivation event
    end

    def context_name
      self.class.name.demodulize.underscore.to_sym
    end
  end
end
