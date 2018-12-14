module OddsFeed
  module Radar
    module Alive
      class Handler < RadarMessageHandler
        SUBSCRIPTION_REPORT_KEY_PREFIX =
          'radar:last_producer_subscription_report:'.freeze

        def handle
          @message = Message.new(@payload['alive'])
          @message.subscribed? ? process_subscribed : process_unsubscribed
        end

        private

        def process_subscribed
          report_subscribed
          update_app_state(true)
        end

        def process_unsubscribed
          update_app_state(false)
          recover_subscription
        end

        def report_subscribed
          timestamp = @message.datetime.to_i
          return if last_subscribed_timestamp > timestamp

          update_subscribed_timestamp(timestamp)
        end

        def recover_subscription
          OddsFeed::Radar::SubscriptionRecovery
            .call(product_id: @message.product_id,
                  start_at: available_recovery_time)
        end

        def available_recovery_time
          timestamp = last_subscribed_timestamp
          return nil if Time.zone.at(timestamp) < 72.hours.ago

          timestamp
        end

        def update_app_state(new_status)
          flag = @message.product.live? ? :live_connected : :pre_live_connected
          ApplicationState.instance.send("#{flag}=", new_status)
        end

        def cache
          Rails.cache
        end

        def last_subscribed_timestamp
          cache.read(subscribed_timestamp_cache_key).to_i
        end

        def update_subscribed_timestamp(timestamp)
          cache.write(subscribed_timestamp_cache_key, timestamp)
        end

        def subscribed_timestamp_cache_key
          SUBSCRIPTION_REPORT_KEY_PREFIX + @message.product_id.to_s
        end
      end
    end
  end
end
