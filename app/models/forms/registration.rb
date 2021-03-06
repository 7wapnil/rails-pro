# frozen_string_literal: true

module Forms
  class Registration
    include ActiveModel::Model

    def initialize(customer_data:)
      @prepared_data = prepared_attributes(customer_data)
    end

    attr_accessor :currency_code, :prepared_data

    validate do
      next if prepared_data[:agreed_with_privacy]

      message = I18n.t('errors.messages.tos_not_accepted')
      errors.add(:agreed_with_privacy, message)
    end

    validate do
      next if customer.valid?

      errors.merge!(customer.errors)
    end

    validate do
      next if prepared_data[:address_attributes].values.all?(&:present?)

      prepared_data[:address_attributes].each do |key, value|
        next if value.present?

        errors.add(key, I18n.t('errors.messages.blank'))
      end
    end

    def customer
      @customer ||= Customer.new(prepared_data)
    end

    def wallet
      @wallet ||= Wallet.new(customer: customer, currency: currency)
    end

    private

    def prepared_attributes(attrs)
      attrs.transform_keys! do |key|
        key.to_s.underscore.to_sym
      end

      @currency_code = attrs.delete(:currency)

      address = attrs.extract!(:country, :city, :street_address,
                               :state, :zip_code)
      attrs.merge(address_attributes: address)
    end

    def currency
      Currency.find_by_code!(currency_code)
    end
  end
end
