module Mts
  class SessionRecovery
    MTS_SESSION_FAILURE_KEY = :mts_session_failed_at

    def recover_from_network_failure!
      return if session_failed_at.blank?

      recover_producer_subscriptions!
      clear_session_failed_at
    end

    def register_failure!
      return if session_failed_at.present?

      timestamp = Time.zone.now
      update_session_failed_at(timestamp)
      Rails.logger.warn "Mts session failed at: #{timestamp}"
    end

    private

    def recover_producer_subscriptions!
      OddsFeed::Radar::Product.available_product_ids.each do |product_id|
        producer = Radar::Producer.find_by_id(product_id)
        producer.recover_subscription!
      end
    end

    def session_failed_at
      Rails.cache.fetch(MTS_SESSION_FAILURE_KEY)
    end

    def update_session_failed_at(timestamp)
      Rails.cache.write(MTS_SESSION_FAILURE_KEY, timestamp)
    end

    def clear_session_failed_at
      Rails.cache.delete(MTS_SESSION_FAILURE_KEY)
    end
  end
end
