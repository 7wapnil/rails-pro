describe Mts::Session do
  let(:example_config) { { Faker::Lorem.word => Faker::Lorem.word } }

  describe 'class methods' do
    subject { Mts::Session }
    describe '#initialize' do
      context 'config passed' do
        it 'sets config based on argument' do
          connection = subject.new(example_config)
          expect(connection.instance_variable_get(:@config))
            .to eq example_config
        end
      end
      context 'config not passed' do
        let(:connection) { subject.new }
        before do
          allow_any_instance_of(subject)
            .to receive(:default_config)
            .and_return(example_config)
        end
        it 'calls default_config' do
          expect(connection)
            .to have_received(:default_config)
        end

        it 'sets config based on default_config' do
          expect(connection.instance_variable_get(:@config))
            .to eq example_config
        end
      end
    end
  end

  describe '.connection' do
    it 'calls Bunny service with specific config' do
      expect(Bunny).to receive(:new).with(example_config)
      Mts::Session.new(example_config).connection
    end
    it 'calls Bunny service only once' do
      expect(Bunny).to receive(:new).and_return({})
        .once.with(example_config)
      conn = Mts::Session.new(example_config)
      2.times do
        conn.connection
      end
    end
  end

  describe '.opened_connection' do
    it 'returns opened connection for new connection' do
      allow(subject.connection).to receive(:open?).and_return(false)

      expect(subject.connection).to receive(:start).and_return(:connection)

      expect(subject.opened_connection).to eq(:connection)
    end

    it 'returns existing connection for opened connection' do
      connection_stub = double
      allow(subject).to receive(:connection).and_return(connection_stub)
      allow(connection_stub).to receive(:open?).and_return(true)

      expect(subject.connection).to_not receive(:start)

      expect(subject.opened_connection).to eq(connection_stub)
    end
  end

  describe '.within_connection' do
    it 'passes control with opened_connection argument' do
      allow(subject).to receive(:opened_connection).and_return(:connection)
      expect { |b| subject.within_connection(&b) }
        .to yield_with_args(:connection)
    end
  end
end
