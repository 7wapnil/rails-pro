module BonusExpiration
  class BaseExpirationStrategy < ApplicationService
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
      if options[:user].nil?
        customer_log(customer_bonus.customer)
      else
        user_log(options[:user], customer_bonus.customer)
      end
    end

    def context_name
      self.class.name.demodulize.underscore.to_sym
    end

    private

    def user_log(user, customer)
      user.log_event :customer_bonus_deactivated,
                     customer_bonus,
                     customer
    end

    def customer_log(user)
      user.log_event :customer_bonus_deactivated,
                     customer_bonus
    end
  end
end
