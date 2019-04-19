# frozen_string_literal: true

describe EntryRequests::BetSettlementService do
  subject { described_class.call(entry_request: entry_request) }

  let(:entry_request) { create(:entry_request, origin: bet) }
  let(:customer_bonus) do
    create(:customer_bonus, :applied, customer: entry_request.customer)
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

  context 'with won bet' do
    let(:bet) do
      create(:bet, :settled, :won, customer: customer_bonus.customer)
    end

    context 'with bet that fits into bonus conditions' do
      before do
        customer_bonus.update(
          min_odds_per_bet: 1.001
        )
      end

      it 'decreases rollover balance by settled bet win amount' do
        expect { subject }
          .to change(customer_bonus, :rollover_balance)
          .by(-bet.amount)
      end
    end

    context 'with bet that don\'t fit into bonus conditions' do
      before do
        customer_bonus.update(
          min_odds_per_bet: 1000
        )
      end

      it 'does not change the rollover_balance' do
        expect { subject }
          .not_to change(customer_bonus, :rollover_balance)
      end
    end
  end

  context 'with lost bet' do
    let(:bet) do
      create(:bet, :settled, :lost, customer: customer_bonus.customer)
    end

    context 'with bet that fits into bonus conditions' do
      before do
        customer_bonus.update(
          min_odds_per_bet: 1.001
        )
      end

      it 'decreases rollover balance by settled bet win amount' do
        expect { subject }
          .to change(customer_bonus, :rollover_balance)
          .by(-bet.amount)
      end
    end
  end

  context 'with void bet' do
    let(:bet) do
      create(:bet, :settled, :void, customer: customer_bonus.customer)
    end

    context 'with bet that fits into bonus conditions' do
      before do
        customer_bonus.update(
          min_odds_per_bet: 1.001
        )
      end

      it 'decreases rollover balance by settled bet win amount' do
        expect { subject }
          .not_to change(customer_bonus, :rollover_balance)
      end
    end
  end
end
