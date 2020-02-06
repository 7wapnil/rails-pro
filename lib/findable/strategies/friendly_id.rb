# frozen_string_literal: true

module Findable
  module Strategies
    module FriendlyId
      protected

      def strict
        raise "##{__method__} should be defined!"
      end

      def value
        raise "##{__method__} should be defined!"
      end

      def friendly
        raise "##{__method__} should be defined!"
      end

      def constantized_resource_class
        raise "##{__method__} should be defined!"
      end

      def verify_friendly_id_strategy!
        return unless friendly
        return no_friendly_id_gem! unless defined?(::FriendlyId)

        no_friendly_id_model! unless friendly_id_model?
      end

      def apply_friendly_id_strategy!(scope)
        scope.friendly.find(value)
      rescue ActiveRecord::RecordNotFound => error
        raise error if strict

        nil
      end

      private

      def no_friendly_id_gem!
        raise 'Add FriendlyId gem to your bundle to use `friendly` option!'
      end

      def friendly_id_model?
        constantized_resource_class.method_defined?(:friendly_id)
      end

      def no_friendly_id_model!
        raise 'Enable FriendlyId to your model to use `friendly` option!'
      end
    end
  end
end
