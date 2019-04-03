describe Mts::ValidationMessagePublisherWorker do
  it { is_expected.to be_processed_in :default }

  describe '.perform' do
    it 'raises on unprocessable input' do
      expect { subject.perform([1, 2]) } .to raise_error(NotImplementedError)
    end

    context 'with processable input' do
      before do
        allow(Mts::Publishers::BetValidation)
          .to receive('publish!')
      end

      let(:bet) { create(:bet) }

      it 'publishes with correct publisher' do
        expect(Mts::Publishers::BetValidation).to receive('publish!')
          .and_return(true)

        subject.perform([bet])
      end

      context 'with unexpected response from server' do
        before do
          allow(Mts::Publishers::BetValidation)
            .to receive('publish!').and_return(false)
        end

        it 'raises an error' do
          expect { subject.perform([bet.id]) } .to raise_error StandardError
        end
      end
    end
  end
end
