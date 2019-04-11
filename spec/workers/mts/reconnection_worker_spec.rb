# frozen_string_literal: true

describe Mts::ReconnectionWorker do
  describe '.perform' do
    context 'MTS connection is healthy' do
      before { create(:mts_connection) }

      it 'returns without actions' do
        expect(subject.perform).to be_nil
      end
    end

    context 'MTS connection is recovering' do
      before { create(:mts_connection, status: MtsConnection::RECOVERING) }

      it 'trigger front end update' do
        allow(::Mts::SingleSession.instance.session)
          .to receive(:opened_connection).and_return(true)

        expect(WebSocket::Client.instance)
          .to receive(:trigger_mts_connection_status_update)

        subject.perform
      end
    end
  end
end
