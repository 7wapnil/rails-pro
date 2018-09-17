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

  describe '.outcome_amount' do
    context 'calculates outcome according to bet state' do
      EXAMPLES = [
        { name: 'simplest case',
          amount: 1, odd_value: 1.0, void_factor: 1, outcome: 1.0 },
        { name: 'decimal amount',
          amount: 1.5234, odd_value: 1.0, void_factor: 1, outcome: 1.5234 },
        { name: 'decimal odd value',
          amount: 1, odd_value: 1.5234, void_factor: 1, outcome: 1.5234 },
        { name: 'decimal void factor',
          amount: 1, odd_value: 1.0, void_factor: 0.7, outcome: 0.7 },
        { name: 'weird small case',
          amount: 0.01, odd_value: 1.001, void_factor: 0.7, outcome: 0.007007 },
        { name: 'extra big case',
          amount: 1_000_000, odd_value: 10.22,
          void_factor: 1, outcome: 10_220_000 }
      ].freeze

      EXAMPLES.each do |example|
        it example[:name] do
          bet =
            build(:bet,
                  amount: example[:amount],
                  odd_value: example[:odd_value],
                  void_factor: example[:void_factor])
          expect(bet.outcome_amount).to be_within(0.01).of(example[:outcome])
        end
      end
    end
  end
end
