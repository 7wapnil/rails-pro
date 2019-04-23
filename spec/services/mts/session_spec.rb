describe Mts::Session do
  let(:example_config) { { Faker::Lorem.word => Faker::Lorem.word } }

  before { create(:mts_connection) }

  describe '#opened_connection' do
    let(:subject) { described_class.instance }

    context 'connection is already open' do
      let(:connection_double) { double }

      before do
        allow(subject).to receive(:connection_open?)
          .and_return(true)

        allow(subject).to receive(:connection).and_return(connection_double)
      end

      it 'returns existing connection for opened connection' do
        expect(subject.opened_connection).to eq(connection_double)
      end

      it 'does not call start_connection' do
        expect(subject.opened_connection).not_to receive(:start_connection)
      end
    end

    context 'connection is not open' do
      let(:connection_double) { double }

      before do
        allow(subject).to receive(:connection_open?)
          .and_return(false)

        allow(subject).to receive(:connection).and_return(connection_double)
      end

      it 'calls #start_connection' do
        expect(subject).to receive(:start_connection)
        subject.opened_connection
      end
    end

    context 'no MTS connection' do
      let(:connection_double) { double }
      let(:error) { Bunny::TCPConnectionFailedForAllHosts }

      before do
        allow(subject).to receive(:connection_open?)
          .and_return(false)

        allow(subject).to receive(:connection).and_return(connection_double)

        allow(connection_double).to receive(:start).and_raise(error)
      end

      it 'raises error' do
        expect { subject.opened_connection }.to raise_error(error)
      end

      it 'updates Application State' do
        allow(subject).to receive(:opened_connection)
        subject.opened_connection
      rescue error
        expect(subject).to have_received(:update_mts_connection_state)
      end

      it 'emits Application State' do
        allow(subject).to receive(:opened_connection)
        subject.opened_connection
      rescue error
        expect(subject).to have_received(:emit_application_state)
      end
    end
  end
end
