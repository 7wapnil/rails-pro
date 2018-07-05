class AuditService < ApplicationService
  def initialize(target:, action:, origin_kind:, origin_id:, payload: {})
    @target = target
    @action = action
    @origin_kind = origin_kind
    @origin_id = origin_id
    @payload = payload
  end

  def call
    AuditLog.create(target: @target,
                    action: @action,
                    origin: { kind: @origin_kind, id: @origin_id },
                    payload: @payload)
  end
end
