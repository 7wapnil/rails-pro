# frozen_string_literal: true

describe Bet do
  subject { build(:bet) }

  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:odd) }
  it { is_expected.to belong_to(:currency) }
  it { is_expected.to belong_to(:customer_bonus) }

  it { is_expected.to have_one(:entry) }
  it { is_expected.to have_one(:entry_request) }
  it { is_expected.to have_one(:recent_win_entry) }

  it { is_expected.to have_many(:entry_requests) }
  it { is_expected.to have_many(:entries) }

  it do
    expect(subject).to validate_numericality_of(:odd_value)
      .is_equal_to(subject.odd.value)
      .on(:create)
  end

  it do
    expect(subject).to validate_numericality_of(:void_factor)
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

  describe 'Bet.expired_prematch' do
    include_context 'frozen_time'

    it 'Returns expired prematch bets' do
      timeout = ENV.fetch('MTS_PREMATCH_VALIDATION_TIMEOUT_SECONDS', 3).to_i
      expired_bets = create_list(:bet, 2,
                                 validation_ticket_sent_at: (timeout + 3)
                                                              .seconds
                                                              .ago,
                                 status: :sent_to_external_validation)
      create_list(:bet, 3,
                  validation_ticket_sent_at: 1.seconds.ago,
                  status: :sent_to_external_validation)
      expected_bets = described_class.expired_prematch

      expect(expected_bets).to match_array(expired_bets)
    end
  end

  describe 'Bet.expired_live' do
    include_context 'frozen_time'

    it 'Returns expired live bets' do
      timeout = ENV.fetch('MTS_LIVE_VALIDATION_TIMEOUT_SECONDS', 10).to_i
      expired_time = (timeout + 3).seconds.ago
      live_event = create(:event, :with_odds, traded_live: true)
      expired_bets = create_list(:bet, 2,
                                 odd: live_event.markets.first.odds.first,
                                 validation_ticket_sent_at: expired_time,
                                 status: :sent_to_external_validation)
      create_list(:bet, 3,
                  validation_ticket_sent_at: 1.seconds.ago,
                  status: :sent_to_external_validation)
      expected_bets = described_class.expired_live

      expect(expected_bets).to match_array(expired_bets)
    end
  end

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
      result = described_class.with_winnings.first
      expect(result.winning).to eq(result.amount * result.odd_value)
    end
  end

  describe 'sort_by_winning_asc' do
    it 'finds bets with calculated winnings sorted asc' do
      create_list(:bet, 2)
      result = described_class.sort_by_winning_asc
      first = result.first
      last = result.last
      expect(first.winning <= last.winning).to be_truthy
    end
  end

  describe 'sort_by_winning_desc' do
    it 'finds bets with calculated winnings sorted desc' do
      create_list(:bet, 2)
      result = described_class.sort_by_winning_desc
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
        expect(bet).to be_settled
        expect(bet.void_factor).to eq(0.5)
        expect(bet).to be_won
        expect(bet).not_to be_lost
      end
      it 'set settlement status to lost' do
        expect(bet.settle!(settlement_status: :lost, void_factor: 0.7))
          .to be_truthy
        expect(bet).to be_settled
        expect(bet.void_factor).to eq(0.7)
        expect(bet).not_to be_won
        expect(bet).to be_lost
      end
    end
  end

  context 'bonus and real money totals' do
    let(:bet) { create(:bet) }
    let(:entry_request) do
      create(:entry_request,
             origin: bet,
             status: EntryRequest::SUCCEEDED,
             kind: EntryRequest::BET)
    end
    let(:currency) { create(:currency) }
    let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
    let(:real_request_amount) { 100 }
    let(:bonus_request_amount) { 150 }
    let(:entry) { create(:entry, amount: 10) }

    before do
      allow(EntryCurrencyRule).to receive(:find_by!) { rule }
      create(:balance_entry_request,
             kind: Balance::REAL_MONEY,
             balance_entry: create(:balance_entry, amount: 10, entry: entry),
             entry_request: entry_request,
             amount: real_request_amount)

      create(:balance_entry_request,
             kind: Balance::BONUS,
             balance_entry: create(:balance_entry, amount: 100, entry: entry),
             entry_request: entry_request,
             amount: bonus_request_amount)
    end

    describe '#real_money_total' do
      it 'returns sum of real money balance entry requests' do
        expect(bet.real_money_total).to eq(real_request_amount)
      end

      it 'returns 0 when entry request is not succeeded' do
        entry_request.failed!

        expect(bet.real_money_total).to be_zero
      end
    end

    describe '#bonus_money_total' do
      it 'returns sum of bonus money balance entry requests' do
        expect(bet.bonus_money_total).to eq(bonus_request_amount)
      end

      it 'returns 0 when entry request is not succeeded' do
        entry_request.failed!

        expect(bet.bonus_money_total).to be_zero
      end
    end
  end

  describe 'filter out non-regular customers bets' do
    let(:regular_customer) { create(:customer, account_kind: :regular) }
    let(:test_customer) { create(:customer, account_kind: :testing) }
    let(:event) { create(:event, :with_odds) }

    before do
      event_odd = event.markets.first.odds.first
      event_odd.bets << create(:bet, customer: regular_customer, amount: 15)
      event_odd.bets << create(:bet, customer: regular_customer, amount: 20)
      event_odd.bets << create(:bet, customer: test_customer)
    end

    it 'returns bets from regular customer' do
      expect(described_class.from_regular_customers).to eq(
        regular_customer.bets
      )
    end
    it 'does not return bets from test customer' do
      expect(described_class.from_regular_customers).not_to include(
        test_customer.bets
      )
    end

    it 'count of bets calculations' do
      bets_count = Event.with_bets_count.find(event.id).bets_count

      expect(bets_count).to eq(2)
    end

    it 'wager calculations' do
      expect(Event.with_wager.find(event.id).wager).to eq(35)
    end
  end
end
