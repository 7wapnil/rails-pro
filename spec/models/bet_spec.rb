describe Bet do
  subject { build(:bet) }

  it { should define_enum_for(:status) }

  it { should belong_to(:customer) }
  it { should belong_to(:odd) }
  it { should belong_to(:currency) }

  it { should have_one(:entry) }
  it { should have_one(:entry_request) }

  it do
    should validate_numericality_of(:odd_value)
      .is_equal_to(subject.odd.value)
      .on(:create)
  end

  it { should allow_value(true, false).for(:result) }

  it do
    should validate_numericality_of(:void_factor)
      .is_greater_than_or_equal_to(0)
      .is_less_than_or_equal_to(1)
      .allow_nil
  end

  BET_SETTLEMENT_OUTCOMES_EXAMPLES = [
    { name: 'Lose entire bet',
      amount: 1, odd_value: 1.0, void_factor: nil,
      result: 0,
      win_amount: 0, refund_amount: 0 },
    { name: 'Win entire bet',
      amount: 1, odd_value: 1.345, void_factor: nil,
      result: 1,
      win_amount: 1.345, refund_amount: 0 },
    { name: 'Refund entire bet',
      amount: 1, odd_value: 1.345, void_factor: 1,
      result: 0,
      win_amount: 0, refund_amount: 1 },
    { name: 'Refund half bet and win other half',
      amount: 1, odd_value: 1.345, void_factor: 0.5,
      result: 1,
      win_amount: 1.345 * 0.5, refund_amount: 0.5 },
    { name: 'Refund half bet and lose other half',
      amount: 1, odd_value: 1.345, void_factor: 0.5,
      result: 0,
      win_amount: 0, refund_amount: 0.5 }
  ].freeze

  describe '.win_amount' do
    BET_SETTLEMENT_OUTCOMES_EXAMPLES.each do |example|
      it example[:name] do
        bet =
          build(:bet,
                amount: example[:amount],
                odd_value: example[:odd_value],
                void_factor: example[:void_factor],
                result: example[:result])

        expect(bet.win_amount).to be_within(0.01).of(example[:win_amount])
      end
    end
  end

  describe '.refund_amount' do
    BET_SETTLEMENT_OUTCOMES_EXAMPLES.each do |example|
      it example[:name] do
        bet =
          build(:bet,
                amount: example[:amount],
                odd_value: example[:odd_value],
                void_factor: example[:void_factor],
                result: example[:result])

        expect(bet.refund_amount)
          .to be_within(0.01).of(example[:refund_amount])
      end
    end
  end
end
