describe BetExternalValidation::Service do
  describe '.call' do
    let(:bet) { create(:bet) }

    before do
      described_class.call(bet)
    end

    it 'performs external validation by publishing ticket to MTS' do
      expect(Mts::MessagePublisherWorker).to have_enqueued_sidekiq_job([bet.id])
    end
  end
end
