# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class BaseHandler < ApplicationService
      ACTIONS = [
        INITIALIZE_START = 'initialize_start',
        UPDATE = 'update',
        INITIALIZE_COMPLETE = 'initialize_complete'
      ].freeze

      def initialize(payload = {})
        @payload = payload
        @data = payload['data']
        @action = payload['action']
      end

      def call
        handle_update_message if action == UPDATE
        health_check!
      end

      protected

      attr_reader :payload, :data, :action

      def handle_update_message
        raise NotImplementedError, 'Implement #handle_update_message method'
      end

      private

      def health_check!
        connection_state.with_lock do
          connection_state.update(status: new_connection_status)
        end
      end

      def connection_state
        @connection_state ||= EveryMatrix::Connection.instance
      end

      def new_connection_status
        return EveryMatrix::Connection::RECOVERING if recovery?
        return EveryMatrix::Connection::HEALTHY if action == INITIALIZE_COMPLETE

        connection_state.status
      end

      def recovery?
        action == INITIALIZE_START && connection_state.dead?
      end
    end
  end
end
