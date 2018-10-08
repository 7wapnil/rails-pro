class Label < ApplicationRecord
  include Loggable

  default_scope { order(name: :asc) }

  acts_as_paranoid

  validates :name, presence: true, length: { minimum: 2 }

  has_and_belongs_to_many :customers

  def loggable_attributes
    { id: id,
      name: name,
      description: description }
  end
end
