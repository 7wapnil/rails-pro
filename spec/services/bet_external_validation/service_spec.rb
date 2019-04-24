describe BetExternalValidation::Service do
  describe '.call' do
    let(:bet) { create(:bet, :sent_to_external_validation) }

    context 'stubbed mode' do
      context 'with stubbed call' do
        before do
          allow(Mts::Mode).to receive(:stubbed?).and_return(true)
          described_class.call(bet)
        end

        it 'avoids external validation by publishing ticket to MTS' do
          expect(Mts::ValidationMessagePublisherWorker)
            .not_to have_enqueued_sidekiq_job([bet.id])
        end

        it 'perform dummy validation' do
          expect(Mts::ValidationMessagePublisherStubWorker)
              .to have_enqueued_sidekiq_job([bet.id])
        end
      end
    end

    context 'non stubbed mode' do
      before do
        expect(Mts::Mode).to receive(:stubbed?).and_return(false)
        described_class.call(bet)
      end

      it 'performs external validation by publishing ticket to MTS' do
        expect(Mts::ValidationMessagePublisherWorker)
          .to have_enqueued_sidekiq_job([bet.id])
      end
    end
  end
end
