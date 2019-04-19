# frozen_string_literal: true

describe Mts::Publishers::BetValidation do
  let(:subject) { described_class.new(bet: bet) }
  let(:subject_call) { subject.publish! }

  let(:bet) { create(:bet) }

  describe '#publish!' do
    before do
      allow(subject).to receive(:send_message!).and_return(true)
    end

    context 'valid params' do
      it 'do not raise error' do
        expect { subject_call }.not_to raise_error(NotImplementedError)
      end

      it 'update bet validation ticket id' do
        subject_call

        expect(bet.validation_ticket_id).not_to be_nil
      end
    end
  end
end
