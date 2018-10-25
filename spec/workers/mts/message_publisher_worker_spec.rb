describe Mts::MessagePublisherWorker do
  it { is_expected.to be_processed_in :default }

  describe '.perform' do
    it 'raises on unprocessable input' do
      expect { subject.perform([1, 2]) }.to raise_error(NotImplementedError)
    end

    context 'with processable input' do
      let(:bet) { create(:bet) }
      let(:ticket_id) { Faker::Alphanumeric.alphanumeric 10 }

      it 'publishes using correct publisher and message' do
        expect(Mts::Messages::ValidationRequest)
          .to receive(:new).with([bet])
                           .and_return(OpenStruct.new(ticket_id: ticket_id))
        expect(Mts::SubmissionPublisher).to receive('publish!').and_return(true)
        subject.perform([bet.id])
      end

      context 'with correct response from server' do
        before do
          allow(Mts::Messages::ValidationRequest)
            .to receive(:new).with([bet])
                             .and_return(OpenStruct.new(ticket_id: ticket_id))
          allow(Mts::SubmissionPublisher)
            .to receive('publish!').and_return(true)

          subject.perform([bet.id])
        end

        it 'sets validation ticket ID to bet' do
          expect(bet.reload.validation_ticket_id).to eq(ticket_id)
        end
      end

      context 'with unexpected response from server' do
        before do
          allow(Mts::SubmissionPublisher)
            .to receive('publish!').and_return(false)
        end

        it 'raises an error' do
          expect { subject.perform([bet.id]) } .to raise_error StandardError
        end
      end
    end
  end
end
