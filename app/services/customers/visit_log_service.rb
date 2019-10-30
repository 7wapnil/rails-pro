module Customers
  class VisitLogService < ApplicationService
    attr_reader :customer, :request, :sign_in

    CUSTOMER_VISIT_OFFSET = ENV.fetch('CUSTOMER_VISIT_OFFSET', 1).to_f.hours

    def initialize(customer, request, sign_in: false)
      @customer = customer
      @request = request
      @sign_in = sign_in
    end

    def call
      customer.update(last_activity_at: Time.zone.now, **new_visit_attributes)
    end

    private

    def new_visit_attributes
      return {} unless new_visit?

      {
        last_visit_at: Time.zone.now,
        last_visit_ip: request.remote_ip,
        visit_count: customer.visit_count + 1
      }
    end

    def new_visit?
      customer.last_visit_at.blank? || sign_in || calculate_offset
    end

    def calculate_offset
      customer.last_visit_at + CUSTOMER_VISIT_OFFSET <= Time.zone.now
    end
  end
end
