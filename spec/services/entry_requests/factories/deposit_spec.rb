# frozen_string_literal: true

describe EntryRequests::Factories::Deposit do
  let(:customer) { create(:customer) }
  let(:currency) { create(:currency) }
  let(:rule) { create(:entry_currency_rule, min_amount: 0, max_amount: 500) }
  let(:percentage) { 25 }
  let(:amount) { 100 }
  let(:rollover_multiplier) { 5 }
  let(:wallet) do
    create(:wallet, customer: customer, currency: currency, amount: 0)
  end

  let(:service_call) do
    described_class.call(wallet: wallet, amount: amount)
  end

  let!(:customer_bonus) do
    create(:customer_bonus,
           customer: customer,
           percentage: percentage,
           wallet: wallet,
           rollover_balance: 20,
           rollover_multiplier: rollover_multiplier)
  end

  before do
    allow(EntryCurrencyRule).to receive(:find_by!) { rule }
    allow(Currency).to receive(:find_by!) { currency }
    allow(BalanceRequestBuilders::Deposit).to receive(:call)
  end

  context 'with customer bonus' do
    before do
      allow(BalanceRequestBuilders::Deposit)
        .to receive(:call)
        .and_call_original

      service_call
    end

    it_behaves_like 'entry requests splitting with bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end

    it 'applies customer bonus only once' do
      expect { service_call }.not_to change(BalanceEntryRequest.bonus, :count)
    end
  end

  context 'without customer bonus' do
    before do
      allow(BalanceRequestBuilders::Deposit)
        .to receive(:call)
        .and_call_original

      CustomerBonus.destroy_all
      wallet.reload
      service_call
    end

    it_behaves_like 'entry requests splitting without bonus' do
      let(:real_money_amount) { 100 }
      let(:bonus_amount) { amount * percentage / 100.0 }
    end
  end

  context 'with valid attributes' do
    let(:bonus) { rand(1..25) }
    let(:total_amount) { amount + bonus }
    let(:wallet_attributes) do
      {
        origin:   wallet,
        currency: wallet.currency,
        customer: wallet.customer
      }
    end

    let(:deposit_attributes) do
      {
        amount: total_amount,
        mode: EntryRequest::CASHIER,
        kind: EntryRequest::DEPOSIT,
        comment: "Deposit #{total_amount} #{wallet.currency} for #{customer}",
        initiator_type: Customer.name,
        initiator_id: wallet.customer_id
      }
    end

    before do
      allow(BalanceCalculations::Deposit)
        .to receive(:call)
        .with(customer_bonus, amount)
        .and_return(real_money: amount, bonus: bonus)
    end

    it 'creates entry request' do
      expect { service_call }.to change(EntryRequest, :count).by(1)
    end

    it 'returns entry request with deposit attributes' do
      expect(service_call).to have_attributes(deposit_attributes)
    end

    it 'returns entry request with wallet attributes' do
      expect(service_call).to have_attributes(wallet_attributes)
    end
  end

  context 'when customer has deposit limit' do
    let!(:deposit_limit) do
      create(:deposit_limit, customer: customer, currency: currency)
    end

    it "raises an error and doesn't proceed" do
      expect { service_call }.to raise_error 'Customer has a deposit limit'
    end
  end

  context 'when customer bonus is expired' do
    let!(:customer_bonus) do
      create(:customer_bonus,
             customer: customer,
             wallet: wallet,
             created_at: 1.year.ago)
    end

    it "raises an error and doesn't proceed" do
      expect { service_call }.to raise_error 'Bonus is expired'
    end

    context 'bonus' do
      include_context 'frozen_time' do
        let(:frozen_time) { Time.zone.now }
      end

      it 'receives expiration reason' do
        expect { service_call }
          .to raise_error(RuntimeError)
          .and change(customer_bonus, :expiration_reason)
          .to('expired_by_date')
      end

      it 'becomes deleted' do
        expect { service_call }
          .to raise_error(RuntimeError)
          .and change(customer_bonus, :deleted_at)
          .to(Time.zone.now)
      end
    end
  end

  context 'not eligible for bonus' do
    context 'accepted' do
      before do
        allow(customer_bonus)
          .to receive(:activated?)
          .and_return(true)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end

    context 'without min deposit' do
      before do
        allow(customer_bonus)
          .to receive(:min_deposit)
          .and_return(nil)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end

    context 'applied?' do
      before do
        allow(customer_bonus)
          .to receive(:applied?)
          .and_return(false)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end

    context 'amount less than min deposit' do
      before do
        allow(customer_bonus)
          .to receive(:min_deposit)
          .and_return(amount + 1)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end
  end
end
