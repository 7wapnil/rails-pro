module Audit
  class Service < ApplicationService
    def initialize(event:, origin_kind:, origin_id:, context:)
      @event = event
      @origin_kind = origin_kind
      @origin_id = origin_id
      @context = context
    end

    def call
      AuditLog.create!(event: @event,
                      origin_kind: @origin_kind,
                      origin_id: @origin_id,
                      context: @context)
    end
  end
end
