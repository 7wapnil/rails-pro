# frozen_string_literal: true

FactoryBot.define do
  factory :free_spin_bonus, class: EveryMatrix::FreeSpinBonus.name do
    bonus_source { 2 }
    number_of_free_rounds { 10 }
    free_rounds_end_date { 1.month.from_now.to_date }
    additional_parameters { '{}' }
    vendor { create(:every_matrix_vendor) }
  end
end
