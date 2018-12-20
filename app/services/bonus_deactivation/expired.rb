module BonusDeactivation
  class Expired < BaseDeactivationStrategy
    def deactivate
      return customer_bonus if customer_bonus.deleted_at

      customer_bonus.tap do |bonus|
        bonus.update!(expiration_reason: reason)
        bonus.destroy!
      end
    end

    private

    def reason
      raise ArgumentError, 'Expiration reason expected!' unless options[:reason]

      options[:reason]
    end
  end
end
