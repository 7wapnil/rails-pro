describe BetExternalValidation::Service do
  describe '.call' do
    let(:bet) { create(:bet) }

    context 'stubbed mode' do
      before do
        expect(Mts::Mode).to receive(:stubbed?).and_return(true)
        described_class.call(bet)
      end

      it 'avoids external validation by publishing ticket to MTS' do
        expect(Mts::MessagePublisherWorker)
          .to_not have_enqueued_sidekiq_job([bet.id])
      end

      it 'perform dummy valdiation' do
        expect(BetExternalValidation::PublisherStub)
          .to have_received(:call).with([bet.id])
      end
    end

    context 'non stubbed mode' do
      before do
        expect(Mts::Mode).to receive(:stubbed?).and_return(false)
        described_class.call(bet)
      end

      it 'performs external validation by publishing ticket to MTS' do
        expect(Mts::MessagePublisherWorker)
          .to have_enqueued_sidekiq_job([bet.id])
      end
    end
  end
end
