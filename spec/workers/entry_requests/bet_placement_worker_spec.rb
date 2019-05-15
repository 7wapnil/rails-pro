# frozen_string_literal: true

describe EntryRequests::BetPlacementWorker do
  subject { described_class.new.perform(entry_request.id) }

  let!(:currency) { create(:currency, code: 'EUR') }
  let(:customer) { create(:customer) }
  let(:wallet) do
    create(:wallet, :brick, customer: customer, currency: currency)
  end

  let!(:live_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let(:odd) { create(:odd, :active, value: 8.87) }
  let(:bonus_balance_amount) { 250 }
  let(:real_amount) { 750 }
  let(:bet_amount) { 10 }
  let(:bet) do
    create(:bet, customer: customer,
                 odd: odd,
                 currency: currency,
                 amount: bet_amount,
                 odd_value: odd.value,
                 status: Bet::INITIAL,
                 customer_bonus: customer.active_bonus)
  end

  let(:entry_request) do
    ::EntryRequests::Factories::BetPlacement.call(bet: bet)
  end

  it_behaves_like 'EntryRequest worker' do
    let(:service_class) { EntryRequests::BetPlacementService }
  end

  context 'bonus applying' do
    let(:original_bonus) { create(:bonus, percentage: 25) }
    let!(:active_bonus) do
      create(:customer_bonus,
             customer: customer,
             wallet: wallet,
             rollover_balance: 10,
             percentage: 25,
             original_bonus: original_bonus)
    end

    let(:expected_bonus_balance) { 247.5 }
    let(:expected_real_balance) { 742.5 }

    before do
      # TODO: REFACTOR AFTER CUSTOMER BONUS IMPLEMENTATION
      allow(active_bonus).to receive(:active?).and_return(true)
      create(:entry_currency_rule,
             currency: currency,
             min_amount: 10,
             max_amount: 100)
      create(:balance,
             kind: Balance::BONUS,
             wallet: wallet,
             amount: bonus_balance_amount)
      create(:balance,
             wallet: wallet,
             amount: real_amount)
      create(
        :entry_currency_rule,
        currency: currency,
        kind: EntryKinds::BET,
        max_amount: 0,
        min_amount: -100
      )
    end

    it 'charges bonus balance for customer with bonus' do
      subject
      wallet.reload
      expect(wallet.bonus_balance.amount).to eq(expected_bonus_balance)
    end

    it 'charges real balance for customer with bonus' do
      subject
      wallet.reload
      expect(wallet.real_money_balance.amount).to eq(expected_real_balance)
    end

    context 'when there is no bonus' do
      let(:expected_real_balance) { real_amount - bet_amount }

      before do
        active_bonus.destroy
        customer.reload
        bet.reload
        subject
      end

      it_behaves_like 'entries splitting without bonus' do
        let(:real_money_amount) { -bet_amount }
      end

      it 'charges real money balance when there is no bonus' do
        expect(wallet.real_money_balance.amount).to eq(expected_real_balance)
      end

      it 'does not charge bonus money balance when there is no bonus' do
        expect(wallet.bonus_balance.amount).to eq(bonus_balance_amount)
      end
    end

    it_behaves_like 'entries splitting with bonus' do
      let(:real_money_amount) { -7.5 }
      let(:bonus_amount) { -2.5 }

      before { subject }
    end
  end
end
