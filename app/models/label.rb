# frozen_string_literal: true

class Label < ApplicationRecord
  include Loggable

  RESERVED_BY_SYSTEM = [
    NEGATIVE_BALANCE = 'negative_balance'
  ].freeze

  enum kind: {
    customer: CUSTOMER = 'customer',
    event:    EVENT    = 'event',
    market:   MARKET   = 'market'
  }

  default_scope { order(name: :asc) }
  scope :non_system, -> { where(system: false) }
  scope :system, -> { where(system: true) }

  acts_as_paranoid

  validates :name, presence: true, length: { minimum: 2 }
  validates_uniqueness_of :keyword, allow_nil: true
  validate :name_eligibility

  has_many :label_joins
  has_many :customers, through: :label_joins,
                       source_type: 'Customer', source: :labelable

  # def self.negative_balance
  RESERVED_BY_SYSTEM.each do |method_name|
    define_singleton_method method_name do
      find_by(keyword: method_name)
    end
  end

  def loggable_attributes
    { id: id,
      name: name,
      description: description }
  end

  private

  def name_eligibility
    return unless RESERVED_BY_SYSTEM
                  .map { |keyword| I18n.t("labels.#{keyword}") }
                  .include?(name)

    errors.add(:name, I18n.t('errors.messages.reserved'))
  end
end
