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

  it do
    should validate_numericality_of(:void_factor)
      .is_greater_than_or_equal_to(0)
      .is_less_than_or_equal_to(1)
      .allow_nil
  end

  BET_SETTLEMENT_OUTCOMES_EXAMPLES = [
    { name: 'Lose entire bet',
      amount: 1, odd_value: 1.0, void_factor: nil,
      settlement_status: :lost,
      win_amount: 0, refund_amount: 0 },
    { name: 'Win entire bet',
      amount: 1, odd_value: 1.345, void_factor: nil,
      settlement_status: :won,
      win_amount: 1.345, refund_amount: 0 },
    { name: 'Refund entire bet',
      amount: 1, odd_value: 1.345, void_factor: 1,
      settlement_status: :lost,
      win_amount: 0, refund_amount: 1 },
    { name: 'Refund half bet and win other half',
      amount: 1, odd_value: 1.345, void_factor: 0.5,
      settlement_status: :won,
      win_amount: 1.345 * 0.5, refund_amount: 0.5 },
    { name: 'Refund half bet and lose other half',
      amount: 1, odd_value: 1.345, void_factor: 0.5,
      settlement_status: :lost,
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
                settlement_status: example[:settlement_status])

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
                settlement_status: example[:settlement_status])

        expect(bet.refund_amount)
          .to be_within(0.01).of(example[:refund_amount])
      end
    end
  end

  describe 'with_winnings' do
    it 'finds bets with calculated winnings' do
      FactoryBot.create(:bet)
      result = Bet.with_winnings.first
      expect(result.winning).to eq(result.amount * result.odd_value)
    end
  end

  describe 'sort_by_winning_asc' do
    it 'finds bets with calculated winnings sorted asc' do
      create_list(:bet, 2)
      result = Bet.sort_by_winning_asc
      first = result.first
      last = result.last
      expect(first.winning <= last.winning).to be_truthy
    end
  end

  describe 'sort_by_winning_desc' do
    it 'finds bets with calculated winnings sorted desc' do
      create_list(:bet, 2)
      result = Bet.sort_by_winning_desc
      first = result.first
      last = result.last
      expect(first.winning >= last.winning).to be_truthy
    end
  end

  describe '.settle!' do
    context 'with accepted bet' do
      let(:bet) { FactoryBot.create(:bet, :accepted) }
      it 'set settlement status to won' do
        expect(bet.settle!(settlement_status: :won, void_factor: 0.5))
          .to be_truthy
        expect(bet.settled?).to be_truthy
        expect(bet.void_factor).to eq(0.5)
        expect(bet.won?).to be_truthy
        expect(bet.lost?).to be_falsey
      end
      it 'set settlement status to lost' do
        expect(bet.settle!(settlement_status: :lost, void_factor: 0.7))
          .to be_truthy
        expect(bet.settled?).to be_truthy
        expect(bet.void_factor).to eq(0.7)
        expect(bet.won?).to be_falsey
        expect(bet.lost?).to be_truthy
      end
    end
  end
end
