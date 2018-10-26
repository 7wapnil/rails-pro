class Label < ApplicationRecord
  include Loggable

  enum kind: { customer: 0, event: 1, market: 2 }

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
