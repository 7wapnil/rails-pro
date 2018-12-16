class Label < ApplicationRecord
  include Loggable

  enum kind: {
    customer: CUSTOMER = 'customer',
    event:    EVENT    = 'event',
    market:   MARKET   = 'market'
  }

  default_scope { order(name: :asc) }

  acts_as_paranoid

  validates :name, presence: true, length: { minimum: 2 }

  has_many :label_joins
  has_many :customers, through: :label_joins,
                       source_type: 'Customer', source: :labelable

  def loggable_attributes
    { id: id,
      name: name,
      description: description }
  end
end
