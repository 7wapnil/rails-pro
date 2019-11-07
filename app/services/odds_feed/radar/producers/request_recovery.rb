# frozen_string_literal: true

module OddsFeed
  module Radar
    module Producers
      class RequestRecovery < ApplicationService
        include JobLogger

        # approximate time of our server instance downtime
        TERMINATION_PROCESS_LENGTH = 10.minutes
        MAX_RECOVERY_LENGTH = 1440.minutes

        ACCEPTED = 'ACCEPTED'

        delegate :last_disconnected_at, :last_subscribed_at,
                 :recovery_requested_at,
                 to: :producer

        def initialize(producer:)
          @producer = producer
          @node_id = ENV['RADAR_MQ_NODE_ID']
          @requested_at = Time.zone.now
          @request_id = requested_at.to_i
        end

        def call
          raise 'Recovery is disabled' if ::Radar::Producer.recovery_disabled?

          request_recovery_with_api!

          raise ::Radar::UnsuccessfulRecoveryError unless successful_response?

          initiate_recovery!
        rescue ::Radar::UnsuccessfulRecoveryError => error
          log_unsuccessful_recovery(error)
          false
        rescue AASM::InvalidTransition
          false
        rescue StandardError => error
          log_job_message(:error, message: error.message, error_object: error)
          false
        end

        private

        attr_reader :producer, :node_id, :requested_at, :request_id, :response

        def request_recovery_with_api!
          @response = ::OddsFeed::Radar::Client
                      .instance
                      .product_recovery_initiate_request(
                        product_code: producer.code,
                        after: recovery_from,
                        node_id: node_id,
                        request_id: request_id
                      )
                      .fetch('response')
        rescue StandardError => error
          raise ::Radar::UnsuccessfulRecoveryError, error.message
        end

        def recovery_from
          return recovery_requested_at if producer.recovering?
          return no_info_about_start_time unless last_disconnected_at
          return max_recovery_at if last_disconnected_at < max_recovery_at

          last_disconnected_at
        end

        def no_info_about_start_time
          last_subscribed_at || TERMINATION_PROCESS_LENGTH.ago
        end

        def max_recovery_at
          @max_recovery_at ||= requested_at - MAX_RECOVERY_LENGTH
        end

        def successful_response?
          response['response_code'] == ACCEPTED
        end

        def initiate_recovery!
          producer.initiate_recovery!(requested_at: requested_at,
                                      snapshot_id: request_id,
                                      node_id: node_id)
        end

        def log_unsuccessful_recovery(error)
          reason = response ? response['message']['__content__'] : error.message

          log_job_message(
            :error,
            message: 'Unsuccessful recovery',
            reason: reason,
            response_status: response ? response['response_code'] : nil,
            error_object: error
          )
        end

        def extra_log_info
          {
            recovery_from: recovery_from&.to_datetime,
            node_id: node_id,
            request_id: request_id,
            recovery_requested_at: requested_at.to_datetime,
            last_recovery_call_at: last_recovery_call_at&.to_datetime,
            delay_between_recovery: recovery_delay
          }
        end

        def last_recovery_call_at
          producer.recovery_requested_at
        end

        def recovery_delay
          return I18n.t('not_available') unless last_recovery_call_at

          requested_at.to_i - last_recovery_call_at.to_i
        end
      end
    end
  end
end
