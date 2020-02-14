# frozen_string_literal: true

module Audit
  class Service < ApplicationService
    include JobLogger

    def initialize(event:, user: nil, customer: nil, context: {})
      @event = event
      @user = user
      @customer = customer
      @context = context
    end

    def call
      LogWriterWorker.perform_async(event: @event,
                                    user_id: @user&.id,
                                    customer_id: @customer&.id,
                                    context: context,
                                    created_at: Time.zone.now)
    end

    private

    def context
      return @context if @context.is_a?(Hash)

      is_loggable = @context.respond_to?(:loggable_attributes)
      return @context.loggable_attributes if is_loggable

      {}
    end
  end
end
