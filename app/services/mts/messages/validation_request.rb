module Mts
  module Messages
    # TODO: Extract parts to different classes
    class ValidationRequest # rubocop:disable Metrics/ClassLength
      include JobLogger

      SUPPORTED_BETS_PER_REQUEST = 1
      MESSAGE_VERSION = '2.1'.freeze
      DEFAULT_STAKE_TYPE = 'total'.freeze
      DEFAULT_SENDER_ID = 25_238
      CUSTOMER_DEFAULT_LANGUAGE = 'EN'.freeze
      DEFAULT_ODDS_CHANGE_BEHAVIOUR = 'none'.freeze

      attr_reader :bets

      def initialize(bets)
        if bets.length > SUPPORTED_BETS_PER_REQUEST
          log_job_failure(NotImplementedError)
          raise NotImplementedError
        end

        @bets = bets
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
          currency: bets_currency,
          channel: distribution_channel.channel,
          bookmaker_id: DEFAULT_SENDER_ID,
          end_customer: end_customer,
          limit_id: Mts::Limit.some
        }
      end

      def end_customer
        {
          ip: customer.last_sign_in_ip.to_s,
          language_id: CUSTOMER_DEFAULT_LANGUAGE,
          id: customer.id.to_s
        }
      end

      def selections
        @bets.map do |bet|
          {
            event_id: bet.odd.market.event.external_id,
            id: Mts::UofId.id(bet.odd),
            odds: Mts::MtsDecimal.from_number(bet.odd_value)
          }
        end
      end

      def formatted_bets
        @bets.map.with_index do |bet, index|
          {
            id: [ticket_id, index].join('_'),
            selected_systems: single_bet_selected_systems,
            stake: {
              value: Mts::MtsDecimal.from_number(bet.amount),
              type: DEFAULT_STAKE_TYPE
            }
          }.merge(selection_refs(bet))
        end
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
        @customer ||= @bets.first.customer
      end

      def bets_currency
        @bets.first.currency.code
      end

      def single_bet_selected_systems
        [1]
      end

      def selection_refs(_bet)
        { selection_refs: [
          {
            selection_index: 0,
            banker: false
          }
        ] }
      end
    end
  end
end
