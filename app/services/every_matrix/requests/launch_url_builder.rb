# frozen-string_literal: true

module EveryMatrix
  module Requests
    class LaunchUrlBuilder < ApplicationService
      def initialize(play_item:, session_id: nil)
        @play_item = play_item
        @session_id = session_id
      end

      def call
        session_id.nil? ? fun_launch_url : real_money_launch_url
      end

      private

      attr_reader :play_item, :session_id

      def fun_launch_url
        play_item.url
      end

      # TODO: extend functionality to dynamically add params

      def real_money_launch_url
        "#{play_item.url}?language=en&funMode=False&_sid=#{session_id}"
      end
    end
  end
end
