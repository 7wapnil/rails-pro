# frozen_string_literal: true

describe Mts::Publishers::BetCancellation do
  let(:subject) { described_class.new(bet: bet) }
  let(:subject_call) { subject.publish! }

  let(:bet) { create(:bet, status: Bet::SENT_TO_EXTERNAL_VALIDATION) }
  let(:ws) { WebSocket::Client.instance }

  describe '#publish!' do
    before do
      allow(subject).to receive(:send_message!).and_return(true)
      allow(ws).to receive(:trigger_bet_update).with(bet)
    end

    context 'valid params' do
      it 'do not raise error' do
        expect { subject_call }.not_to raise_error
      end

      it 'update bet status' do
        subject_call

        expect(bet.status).to eq(Bet::PENDING_CANCELLATION)
      end

      it 'emits a websocket message' do
        expect(ws).to receive(:trigger_bet_update)

        subject_call
      end
    end
  end
end
