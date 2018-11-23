class ImpersonatedCustomerDecorator < ApplicationDecorator
  decorates :customer
  delegate_all

  attr_accessor :impersonated_by

  def initialize(model, impersonated_by)
    @impersonated_by = impersonated_by
    super(model)
  end

  def log_event(event, context = {})
    Audit::Service.call(event: "impersonated.#{event}",
                        user: impersonated_by,
                        customer: model,
                        context: context)
  end
end
