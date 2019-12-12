describe Mts::ValidationResponseHandler do
  context 'rejected bet' do
    let(:refund_double) { double }
    let(:comment) { 'Bet failed external validation.' }
    let!(:bet) do
      create(:bet, :with_placement_entry, :sent_to_external_validation,
             validation_ticket_id: '1')
    end
    let(:payload) do
      %({"version":"2.3","result":{"status":"rejected","ticketId":"1"}})
    end

    before do
      allow(refund_double).to receive(:id)
      allow(EntryRequests::BetRefundWorker)
        .to receive(:perform_async)
    end

    it 'does not change bet status' do
      described_class.call(payload)
      bet.reload
      expect(bet).to be_sent_to_external_validation
    end

    it 'calls bet refund worker' do
      described_class.call(payload)

      expect(EntryRequests::BetRefundWorker).to have_received(:perform_async)
    end

    it 'creates refund entry request' do
      expect(EntryRequests::Factories::Refund)
        .to receive(:call)
        .with(entry: bet.entry, comment: comment)
        .and_return(refund_double)

      described_class.call(payload)
    end
  end

  context 'rejected bet with retry attribute' do
    let(:refund_double) { double }
    let(:comment) { 'Bet failed external validation.' }
    let!(:bet) do
      create(:bet, :with_placement_entry, :sent_to_external_validation,
             validation_ticket_id: '1', odds_change: true)
    end
    let!(:bet_legs) { create_list(:bet_leg, 2, bet: bet) }
    let(:payload) do
      %({"version":"2.3","result":{"status":"rejected","ticketId":"1"}})
    end

    before do
      allow(EntryRequests::BetRefundWorker)
        .to receive(:perform_async)
      allow(BetExternalValidation::Service)
        .to receive(:call)
    end

    context 'with outdated bet leg' do
      let!(:updated_odd) do
        bet.bet_legs
           .sample
           .odd
           .tap { |odd| odd.update(value: 5) }
           .reload
      end
      let(:outdated_bet_leg) { bet.bet_legs.find_by(odd_id: updated_odd.id) }

      before { described_class.call(payload) }

      it 'does not call bet refund worker' do
        expect(EntryRequests::BetRefundWorker)
          .not_to have_received(:perform_async)
      end

      it 'sends bet to external validation one more time' do
        expect(BetExternalValidation::Service).to have_received(:call)
      end

      it 'refreshes odds values for outdated bet leg' do
        expect(outdated_bet_leg.odd_value).to eq(updated_odd.value)
      end
    end

    context 'without outdated bet leg' do
      before { described_class.call(payload) }

      it 'calls bet refund worker' do
        expect(EntryRequests::BetRefundWorker)
          .to have_received(:perform_async)
      end

      it 'does re-send bet to external validation' do
        expect(BetExternalValidation::Service)
          .not_to have_received(:call)
      end
    end
  end

  context 'accepted bet' do
    let!(:bet) do
      create(:bet, :with_placement_entry, :sent_to_external_validation,
             validation_ticket_id: '1')
    end

    let!(:entry) do
      create(:entry, :with_real_money_balance_entry,
             kind: Entry::BET,
             origin: bet)
    end

    let(:payload) do
      %({"version":"2.3","result":{"status":"accepted","ticketId":"1"}})
    end

    let(:customers_summary) { create(:customers_summary) }

    it 'changes bet status to accepted' do
      described_class.call(payload)

      bet.reload
      expect(bet.accepted?).to eq true
    end

    it 'changes calls summary update worker' do
      expect(Customers::Summaries::BalanceUpdateWorker).to(
        receive(:perform_async)
          .with(
            Date.current,
            entry.id
          )
      )

      described_class.call(payload)
    end
  end
end
