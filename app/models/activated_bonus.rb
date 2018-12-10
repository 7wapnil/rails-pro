class ActivatedBonus < ApplicationRecord
  enum kind: Bonus.kinds
  belongs_to :customer
  belongs_to :wallet
  belongs_to :original_bonus, class_name: 'Bonus', optional: true

  acts_as_paranoid

  def deactivate!
    destroy!
  end
end
