describe Mts::ValidationResponseHandler do
  describe '.new' do
    let(:payload) { %({"version":"2.1","foo":"bar"}) }

    it 'stores validation response message to response variable' do
      service = described_class.new(%({"version":"2.1","foo":"bar"}))
      expect(service.instance_variable_get(:@response)
               .message[:foo]).to eq 'bar'
    end
  end

  describe '.call' do
    context 'rejected bet' do
      let(:refund_double) { double }
      let(:comment) { 'Bet failed external validation.' }
      let!(:bet) do
        create(:bet, :sent_to_external_validation, validation_ticket_id: '1')
      end
      let(:payload) do
        %({"version":"2.1","result":{"status":"rejected","ticketId":"1"}})
      end

      before do
        allow(refund_double).to receive(:id)
        allow(EntryRequests::RefundWorker)
          .to receive(:perform_async).and_return(true)
      end

      it 'changes bet status to rejected' do
        described_class.call(payload)
        bet.reload
        expect(bet.rejected?).to eq true
      end

      it 'creates refund entry request' do
        expect(EntryRequests::Factories::Refund)
          .to receive(:call)
          .with(entry: bet.entry, comment: comment)
          .and_return(refund_double)

        described_class.call(payload)
      end
    end

    context 'accepted bet' do
      let!(:bet) do
        create(:bet, :sent_to_external_validation, validation_ticket_id: '1')
      end
      let(:payload) do
        %({"version":"2.1","result":{"status":"accepted","ticketId":"1"}})
      end

      it 'changes bet status to accepted' do
        described_class.call(payload)
        bet.reload
        expect(bet.accepted?).to eq true
      end
    end
  end
end
