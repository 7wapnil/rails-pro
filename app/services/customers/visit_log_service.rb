module Customers
  class VisitLogService < ApplicationService
    attr_reader :customer, :request

    def initialize(customer, request)
      @customer = customer

      @request = request
    end

    def call
      update_tracked_fields!
    end

    private

    def update_tracked_fields
      customer.visit_count   ||= 1
      customer.last_visit_at ||= Time.now.utc

      if calculate_offset
        customer.last_visit_at = Time.now.utc

        customer.last_visit_ip = extract_ip_from

        customer.visit_count += 1
      end

      customer.last_activity_at = Time.now.utc
    end

    def update_tracked_fields!
      update_tracked_fields
      customer.save(validate: false)
    end

    def calculate_offset
      customer.last_visit_at + ENV['VISIT_OFFSET'].to_i.hour <= Time.now.utc
    end

    def extract_ip_from
      request.remote_ip
    end
  end
end
