# frozen_string_literal: true

describe BetExternalValidation::Service do
  describe '.call' do
    let(:bet) { create(:bet, :sent_to_external_validation, :with_bet_leg) }

    context 'stubbed mode' do
      context 'with stubbed call' do
        before do
          allow(Mts::Mode).to receive(:stubbed?).and_return(true)
          described_class.call(bet)
        end

        it 'avoids external validation by publishing ticket to MTS' do
          expect(Mts::ValidationMessagePublisherWorker)
            .not_to have_enqueued_sidekiq_job(bet.id)
        end

        it 'perform dummy validation' do
          expect(Mts::ValidationMessagePublisherStubWorker)
            .to have_enqueued_sidekiq_job(bet.id)
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
          .to have_enqueued_sidekiq_job(bet.id)
      end
    end

    describe 'live_bet_delay' do
      let(:service) { described_class.new(bet) }

      before do
        allow(service).to receive(:live_producer?).and_return(true)
      end

      it 'live_bet_delay = 0, when limit = 0' do
        allow(service)
          .to receive(:global_live_bet_delay)
          .and_return(0)

        allow(service)
          .to receive(:title_live_bet_delay)
          .and_return(0)

        expect(service.send(:live_bet_delay)).to eq(0)
      end

      it 'live_bet_delay = 5, when customer limit = 5' do
        allow(service)
          .to receive(:global_live_bet_delay)
          .and_return(5)

        allow(service)
          .to receive(:title_live_bet_delay)
          .and_return(0)

        expect(service.send(:live_bet_delay)).to eq(5)
      end

      it 'live_bet_delay = 10, when event limit = 10' do
        allow(service)
          .to receive(:global_live_bet_delay)
          .and_return(0)

        allow(service)
          .to receive(:title_live_bet_delay)
          .and_return(10)

        expect(service.send(:live_bet_delay)).to eq(10)
      end
    end
  end
end
