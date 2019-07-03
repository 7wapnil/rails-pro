module Customers
  class RelevantIpAddressService < ApplicationService
    def initialize(customer)
      @customer = customer
    end

    def call
      customer.current_sign_in_ip || customer.last_sign_in_ip
    end

    private

    attr_reader :customer
  end
end
