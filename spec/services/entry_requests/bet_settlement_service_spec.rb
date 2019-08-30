# frozen_string_literal: true

describe EntryRequests::BetSettlementService do
  subject { described_class.call(entry_request: entry_request) }

  let(:customer_bonus) { create(:customer_bonus) }
  let(:bet) { create(:bet, :settled, :won) }
  let(:entry_request) do
    create(:entry_request, origin: bet, customer: customer_bonus.customer)
  end

  before { allow(::WalletEntry::AuthorizationService).to receive(:call) }

  context 'entry request with pending bet' do
    let(:bet) { create(:bet, status: Bet::INITIAL) }

    let(:error_message) do
      I18n.t('errors.messages.entry_request_for_settled_bet', bet_id: bet.id)
    end

    before { subject }

    it 'does not call authorization service' do
      expect(::WalletEntry::AuthorizationService).not_to have_received(:call)
    end

    it 'bet is still pending' do
      expect(bet.reload.status).to eq(Bet::INITIAL)
    end

    it 'is not proceeded' do
      expect(entry_request).to have_attributes(
        status: EntryRequest::FAILED,
        result: { 'message' => error_message }
      )
    end
  end

  context 'entry request with bet that can be settled' do
    it 'is proceeded' do
      expect(::WalletEntry::AuthorizationService)
        .to receive(:call)
        .with(entry_request)
        .and_return(:result)

      subject
    end
  end

  context 'with failed entry request' do
    let(:error) { Faker::WorldOfWarcraft.quote }
    let(:entry_request) do
      create(:entry_request, origin: bet,
                             status: EntryRequest::FAILED,
                             result: { message: error })
    end

    before { subject }

    it 'does not call authorization service' do
      expect(WalletEntry::AuthorizationService).not_to have_received(:call)
    end

    it 'bet is sent to manual settlement' do
      expect(bet.reload).to have_attributes(
        status: Bet::PENDING_MANUAL_SETTLEMENT,
        notification_message: error,
        notification_code: Bets::Notification::INTERNAL_SERVER_ERROR
      )
    end
  end

  context 'with authorization failure' do
    let(:error) { Faker::WorldOfWarcraft.quote }
    let(:entry_request) do
      create(:entry_request, origin: bet, result: { message: error })
    end

    before { subject }

    it 'bet is sent to manual settlement' do
      expect(bet.reload).to have_attributes(
        status: Bet::PENDING_MANUAL_SETTLEMENT,
        notification_message: error,
        notification_code: Bets::Notification::INTERNAL_SERVER_ERROR
      )
    end
  end
end
