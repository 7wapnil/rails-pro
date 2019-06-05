module Customers
  class RelevantIpAddressService < ApplicationService
    attr_reader :customer

    def initialize(customer)
      @customer = customer
    end

    def call
      customer.current_sign_in_ip || customer.last_sign_in_ip
    end
  end
end
