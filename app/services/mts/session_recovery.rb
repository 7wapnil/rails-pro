class SessionRecovery
  def recover_from_network_failure!
    Radar::Product.available_product_ids.each do |product_id|
      AliveMessage.recover!(product_id: product_id)
    end
  end

  def register_failure!
    timestamp = Time.now.getutc
    session_failure(timestamp)
  end

  private

  def session_failure(timestamp)
    Rails.cache.write(:last_session_failure, timestamp)
  end
end
