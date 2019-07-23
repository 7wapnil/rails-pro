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
  let(:original_bonus) { create(:bonus, percentage: percentage) }
  let!(:customer_bonus) do
    create(:customer_bonus, :initial,
           customer: customer,
           percentage: percentage,
           wallet: wallet,
           rollover_balance: 20,
           rollover_multiplier: rollover_multiplier,
           original_bonus: original_bonus)
  end
  let(:comment) { Faker::Lorem.sentence }
  let(:initiator) { customer }
  let(:mode) { EntryRequest::SKRILL }
  let(:transaction) do
    Payments::Transactions::Deposit.new(
      method: mode,
      customer: customer,
      amount: amount,
      comment: comment,
      initiator: initiator,
      currency_code: currency.code
    )
  end
  let(:service_call) do
    described_class.call(
      transaction: transaction,
      customer_bonus: customer_bonus
    )
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
    let(:customer_bonus) {}

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
        origin:   kind_of(Deposit),
        currency: wallet.currency,
        customer: wallet.customer
      }
    end

    let(:mode) { EntryRequest.modes.keys.sample }
    let(:admin) { create(:user) }

    let(:deposit_attributes) do
      {
        amount: total_amount,
        mode: mode,
        kind: EntryRequest::DEPOSIT,
        comment: comment,
        initiator_type: User.name,
        initiator_id: admin.id
      }
    end

    let(:initiator) { admin }

    let(:service_call) do
      described_class.call(
        transaction: transaction,
        customer_bonus: customer_bonus
      )
    end

    before do
      allow(BalanceCalculations::Deposit)
        .to receive(:call)
        .with(amount, original_bonus, no_bonus: false)
        .and_return(real_money: amount, bonus: bonus)
    end

    it 'creates entry request' do
      expect { service_call }.to change(EntryRequest, :count).by(1)
    end

    it 'creates deposit request' do
      expect { service_call }.to change(Deposit, :count).by(1)
    end

    it 'returns entry request with deposit attributes' do
      expect(service_call).to have_attributes(deposit_attributes)
    end

    it 'returns entry request with wallet attributes' do
      expect(service_call).to have_attributes(wallet_attributes)
    end

    it 'returns deposit request with assigned customer bonus' do
      expect(service_call.origin.customer_bonus).to eq(customer_bonus)
    end
  end

  context 'with initiator and without passed comment' do
    let(:admin) { create(:user) }
    let(:comment) { nil }
    let(:initiator) { admin }
    let(:service_call) do
      described_class.call(transaction: transaction)
    end

    let(:message) do
      "Deposit #{amount} #{currency} real money " \
      "and 0 #{customer_bonus.wallet.currency.code} bonus money " \
      "(#{customer_bonus.code} bonus code) " \
      "for #{customer} by #{admin}"
    end

    before do
      allow(BalanceCalculations::Deposit)
        .to receive(:call)
        .and_return(real_money: amount)
    end

    it 'mentions him in comment' do
      expect(service_call.comment).to eq(message)
    end
  end

  context 'without impersonated person and passed comment' do
    let(:message) do
      "Deposit #{amount} #{currency} real money " \
      "and 0 #{customer_bonus.wallet.currency.code} bonus money " \
      "(#{customer_bonus.code} bonus code) " \
      "for #{customer}"
    end
    let(:comment) { nil }
    let(:initiator) {}

    before do
      allow(BalanceCalculations::Deposit)
        .to receive(:call)
        .and_return(real_money: amount)
    end

    it 'does not mention him in comment' do
      expect(service_call.comment).to eq(message)
    end

    it 'sets wallet customer as initiator' do
      expect(service_call.initiator).to eq(wallet.customer)
    end
  end

  context 'without mode' do
    it 'sets mode as CASHIER' do
      expect(service_call.mode).to eq(EntryRequest::SKRILL)
    end
  end

  context 'when customer failed a lot of deposit attempts' do
    let!(:deposit_attempts) do
      create_list(
        :entry_request,
        Deposits::VerifyDepositAttempt::MAX_DEPOSIT_ATTEMPTS,
        :deposit,
        customer: customer,
        created_at: 2.hours.ago
      )
    end

    it 'fails created empty request' do
      expect(service_call).to have_attributes(
        status: EntryRequest::FAILED,
        result: {
          'attribute' => 'attempts',
          'message' => I18n.t('errors.messages.deposit_attempts_exceeded')
        }
      )
    end
  end

  context 'when customer over-used a deposit limit' do
    let!(:deposit_limit) do
      create(:deposit_limit, customer: customer,
                             currency: currency,
                             value: amount - 1)
    end

    it 'fails created empty request' do
      expect(service_call).to have_attributes(
        status: EntryRequest::FAILED,
        result: {
          'attribute' => 'limit',
          'message' => I18n.t('errors.messages.deposit_limit_exceeded')
        }
      )
    end

    context 'bonus' do
      include_context 'frozen_time' do
        let(:frozen_time) { Time.zone.now }
      end

      it 'becomes closed' do
        service_call
        expect(customer_bonus).to be_failed
      end
    end
  end

  context 'not eligible for bonus' do
    context 'accepted' do
      before do
        allow(customer_bonus)
          .to receive(:active?)
          .and_return(true)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end

    context 'without min deposit' do
      before do
        allow(original_bonus)
          .to receive(:min_deposit)
          .and_return(nil)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end

    context 'amount less than min deposit' do
      before do
        allow(original_bonus)
          .to receive(:min_deposit)
          .and_return(amount + 1)
      end

      it 'ignores bonus in amount calculation' do
        expect(service_call.amount).to eq(amount)
      end
    end
  end
end
