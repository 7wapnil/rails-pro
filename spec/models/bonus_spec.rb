describe Bonus do
  context 'validations' do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_presence_of(:rollover_multiplier) }
    it { is_expected.to validate_presence_of(:max_rollover_per_bet) }
    it { is_expected.to validate_presence_of(:max_deposit_match) }
    it { is_expected.to validate_presence_of(:min_odds_per_bet) }
    it { is_expected.to validate_presence_of(:min_deposit) }
    it { is_expected.to validate_presence_of(:valid_for_days) }
    it { is_expected.to validate_presence_of(:expires_at) }
    it { is_expected.to validate_presence_of(:percentage) }

    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }

    # rubocop:disable Metrics/LineLength
    it { is_expected.to validate_numericality_of(:rollover_multiplier).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:max_rollover_per_bet).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:max_deposit_match).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:min_odds_per_bet).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:min_deposit).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:valid_for_days).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:percentage).is_greater_than_or_equal_to(0) }
    it { is_expected.to allow_value(true, false).for(:repeatable) }
    # rubocop:enable Metrics/LineLength
  end

  describe '.active' do
    let!(:active_bonus) do
      create(:bonus, expires_at: Time.zone.now + 1.month)
    end
    let(:expired_bonus) do
      create(:bonus, expires_at: Time.zone.now - 1.month)
    end

    it 'returns not expired bonuses' do
      expect(described_class.active).to match_array([active_bonus])
    end
  end
end
