module Mts
  class SessionRecovery
    def recover_from_network_failure!
      return if session_failure_getter.present?
      OddsFeed::Radar::Product.available_product_ids.each do |product_id|
        Radar::AliveMessage.recover!(product_id: product_id)
      end
      session_clear
    end

    def register_failure!
      return if session_failure_getter.present?
      timestamp = Time.now.getutc
      session_failure(timestamp)
      Rails.logger.warn "Mts session failed at: #{timestamp}"
    end

    private

    def session_failure(timestamp)
      Rails.cache.write(:last_session_failure, timestamp)
    end

    def session_failure_getter
      Rails.cache.fetch(:last_session_failure)
    end

    def session_clear
      Rails.cache.delete(:last_session_failure)
    end
  end
end
