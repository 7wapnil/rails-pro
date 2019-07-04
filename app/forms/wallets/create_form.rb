# frozen_string_literal: true

module Wallets
  class CreateForm
    include ActiveModel::Model

    delegate :amount, :currency_id, :customer_id, :currency, :customer,
             to: :subject

    validates :amount, numericality: true

    validate :currency_uniqueness
    validate :fiat_uniqueness, if: -> { fiat? && !duplicate? }

    attr_accessor :subject

    def submit!
      validate!
      subject.tap(&:save)
    end

    private

    def currency_uniqueness
      return unless duplicate?

      errors.add(:base, I18n.t('errors.messages.wallets.not_unique'))
    end

    def fiat_uniqueness
      return unless customer && customer.wallets.fiat.exists?

      errors.add(:base, I18n.t('errors.messages.wallets.fiat_not_unique'))
    end

    def fiat?
      currency&.fiat?.present?
    end

    def duplicate?
      customer&.wallets&.exists?(currency: currency)
    end
  end
end
