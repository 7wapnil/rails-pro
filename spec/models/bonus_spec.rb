describe Bonus do
  context 'validations' do
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:kind) }
    it { should validate_presence_of(:rollover_multiplier) }
    it { should validate_presence_of(:max_rollover_per_bet) }
    it { should validate_presence_of(:max_deposit_match) }
    it { should validate_presence_of(:min_odds_per_bet) }
    it { should validate_presence_of(:min_deposit) }
    it { should validate_presence_of(:valid_for_days) }
    it { should validate_presence_of(:expires_at) }
    it { should validate_presence_of(:percentage) }

    it { should validate_uniqueness_of(:code).case_insensitive }

    # rubocop:disable Metrics/LineLength
    it { should validate_numericality_of(:rollover_multiplier).is_greater_than(0) }
    it { should validate_numericality_of(:max_rollover_per_bet).is_greater_than(0) }
    it { should validate_numericality_of(:max_deposit_match).is_greater_than(0) }
    it { should validate_numericality_of(:min_odds_per_bet).is_greater_than(0) }
    it { should validate_numericality_of(:min_deposit).is_greater_than(0) }
    it { should validate_numericality_of(:valid_for_days).is_greater_than(0) }
    it { should validate_numericality_of(:percentage).is_greater_than_or_equal_to(0) }
    # rubocop:enable Metrics/LineLength
  end
end
