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
      AuditLog.create!(event: @event,
                       user_id: @user&.id,
                       customer_id: @customer&.id,
                       context: context)
    rescue ::Mongoid::Errors::MongoidError, ::Mongo::Error => e
      log_job_message(
        :error,
        message: "Audit Service raised error: #{e.message}",
        context: context,
        event: @event,
        user_id: @user&.id,
        customer_id: @customer&.id
      )
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
