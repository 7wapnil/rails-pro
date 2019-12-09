# frozen_string_literal: true

module Mts
  module Messages
    class ValidationRequest
      include JobLogger

      SUPPORTED_BETS_PER_REQUEST = 1
      MESSAGE_VERSION = '2.3'
      DEFAULT_STAKE_TYPE = 'total'
      CUSTOMER_DEFAULT_LANGUAGE = 'EN'
      DEFAULT_ODDS_CHANGE_BEHAVIOUR = 'none'
      STAKE_MULTIPLIER = 10_000

      attr_reader :bet

      def initialize(bets)
        if bets.length > SUPPORTED_BETS_PER_REQUEST
          log_job_failure(NotImplementedError)
          raise NotImplementedError
        end

        @bet = bets.first
      end

      def to_h
        root_attributes.merge(
          sender: sender,
          selections: selections,
          bets: formatted_bets
        )
      end

      def to_formatted_hash
        ::HashDeepFormatter
          .deep_transform_keys(to_h) { |key| key.to_s.camelize(:lower) }
      end

      def ticket_id
        'MTS_Test_' + created_at.to_i.to_s
      end

      private

      # message structure

      def root_attributes
        {
          version: MESSAGE_VERSION,
          timestamp_utc: created_at,
          ticket_id: ticket_id,
          test_source: !Mts::Mode.production?,
          odds_change: DEFAULT_ODDS_CHANGE_BEHAVIOUR
        }
      end

      def sender
        unless distribution_channel.channel == 'internet'
          log_job_failure(NotImplementedError)
          raise NotImplementedError
        end

        {
          currency: Currency::PRIMARY_CODE,
          channel: distribution_channel.channel,
          bookmaker_id: ENV['MTS_BOOKMAKER_ID'].to_i,
          end_customer: end_customer,
          limit_id: ENV.fetch('MTS_LIMIT_ID')
        }
      end

      def end_customer
        {
          ip: Customers::RelevantIpAddressService.call(customer).to_s,
          language_id: CUSTOMER_DEFAULT_LANGUAGE,
          id: customer.id.to_s
        }
      end

      def selections
        raise NotImplementedError
      end

      def formatted_bets
        raise NotImplementedError
      end

      # InternetDistributionChannel blueprint

      def distribution_channel
        @distribution_channel ||= internet_distribution_channel
      end

      def internet_distribution_channel
        OpenStruct
          .new(
            channel: 'internet',
            requirements: internet_distribution_channel_requirements
          )
      end

      def internet_distribution_channel_requirements
        {
          customer_is_registered: true,
          customer_id: true,
          shop_id: nil,
          terminal_id: nil,
          end_customer_ip: true,
          end_customer_device_id: false,
          end_customer_languge: true
        }
      end

      def created_at
        @created_at ||= (Time.now.to_f * 1000).to_i
      end

      def customer
        @customer ||= bet.customer
      end

      def bets_currency
        bet.currency.code
      end
    end
  end
end
