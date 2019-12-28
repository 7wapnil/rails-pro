# frozen_string_literal: true

module Customers
  class UpdateForm
    include ActiveModel::Model

    attr_accessor :subject,
                  :first_name,
                  :last_name,
                  :city,
                  :zip_code,
                  :street_address,
                  :state,
                  :phone

    validates :subject,
              :first_name,
              :last_name,
              :city,
              :zip_code,
              :street_address,
              :state,
              :phone,
              presence: true

    validates :phone, phone: true

    def submit!
      validate!

      subject.tap { |customer| customer.update!(update_attributes) }
    end

    private

    def update_attributes
      {
        first_name: first_name,
        last_name: last_name,
        phone: phone,
        address_attributes: {
          state: state,
          city: city,
          zip_code: zip_code,
          street_address: street_address
        }
      }
    end
  end
end
