# frozen_string_literal: true

describe Mts::Publishers::BetValidation do
  let(:subject) { described_class.new(bet: bet) }
  let(:subject_call) { subject.publish! }

  let(:bet) { create(:bet) }
  let(:connection_double) { double }
  let(:queue_double) { double }

  before do
    allow(ENV)
      .to receive(:fetch)
      .with('MTS_LIMIT_ID')
      .and_return(1)
  end

  describe '#publish!' do
    before do
      allow(::Mts::Session.instance).to receive(:opened_connection)
        .and_return(connection_double)
      allow(connection_double).to receive(:create_channel)
        .and_return(connection_double)
      allow(connection_double).to receive(:exchange)
        .and_return(connection_double)
      allow(connection_double).to receive(:close)
        .and_return(connection_double)
      allow(connection_double).to receive(:publish)
        .and_return(true)
      allow(connection_double).to receive(:queue)
        .and_return(queue_double)
      allow(queue_double).to receive(:bind)
    end

    context 'valid params' do
      it 'do not raise error' do
        expect { subject_call }.not_to raise_error
      end

      it 'update bet validation ticket id' do
        subject_call

        expect(bet.validation_ticket_id).not_to be_nil
      end

      it 'sends message with Mts session' do
        expect(subject).to receive(:create_exchange)
          .with(connection_double)
          .and_return(connection_double)

        subject_call
      end
    end
  end
end
