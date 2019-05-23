# frozen_string_literal: true

describe EntryRequests::BetSettlementService do
  subject { described_class.call(entry_request: entry_request) }

  let(:customer_bonus) { create(:customer_bonus) }
  let(:entry_request) do
    create(:entry_request, origin: bet, customer: customer_bonus.customer)
  end

  before do
    allow(::WalletEntry::AuthorizationService).to receive(:call)
  end

  context 'entry request with pending bet' do
    let(:bet) { create(:bet) }

    let(:error_message) do
      I18n.t('errors.messages.entry_request_for_settled_bet', bet_id: bet.id)
    end

    before { subject }

    it 'is not proceeded' do
      expect(entry_request).to have_attributes(
        status: EntryRequest::FAILED,
        result: { 'message' => error_message }
      )
    end
  end

  context 'entry request with bet that can be settled' do
    let(:bet) { create(:bet, :settled, :won) }

    it 'is proceeded' do
      expect(::WalletEntry::AuthorizationService)
        .to receive(:call)
        .with(entry_request)

      subject
    end
  end

  context 'with failed entry request' do
    let(:entry_request) do
      create(:entry_request, origin: bet, status: EntryRequest::FAILED)
    end

    it "doesn't proceed" do
      expect(WalletEntry::AuthorizationService).not_to receive(:call)
    end
  end

  context 'with positive rollover' do
    before { allow(CustomerBonuses::CompleteWorker).to receive(:perform_async) }

    let(:bet) { create(:bet, :settled, customer_bonus: customer_bonus) }
    let(:customer_bonus) do
      create(:customer_bonus, rollover_initial_value: 100_000)
    end

    it 'does not call CustomerBonuses::Complete' do
      subject
      expect(CustomerBonuses::CompleteWorker).not_to have_received(:perform_async)
    end
  end

  context 'with negative rollover' do
    before do
      allow(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      allow(WalletEntry::AuthorizationService)
        .to receive(:call).and_return(create(:entry))
    end

    let(:bet) { create(:bet, :settled, customer_bonus: customer_bonus) }
    let(:customer_bonus) do
      create(:customer_bonus, rollover_initial_value: -100_000)
    end

    it 'calls CustomerBonuses::Complete' do
      subject
      expect(CustomerBonuses::CompleteWorker).to have_received(:perform_async)
    end
  end

  context 'with authorization failure' do
    before do
      allow(CustomerBonuses::CompleteWorker).to receive(:perform_async)
      allow(WalletEntry::AuthorizationService).to receive(:call).and_return(nil)
    end

    let(:bet) { create(:bet, :settled, customer_bonus: customer_bonus) }
    let(:customer_bonus) do
      create(:customer_bonus, rollover_initial_value: -100_000)
    end

    it 'calls CustomerBonuses::Complete' do
      subject
      expect(CustomerBonuses::CompleteWorker).not_to have_received(:perform_async)
    end
  end
end
