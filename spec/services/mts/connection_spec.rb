describe Mts::Connection do
  let(:example_config) { { Faker::Lorem.word => Faker::Lorem.word } }

  describe 'class methods' do
    subject { Mts::Connection }
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

    describe '#connection' do
      it 'creates new instance of connection and pass config' do
        expect(subject).to receive(:new).with(example_config).and_call_original
        subject.connection(example_config)
      end
      it 'calls instance method connecton' do
        expect_any_instance_of(subject).to receive(:connection)
        subject.connection
      end
    end
  end

  describe '.connection' do
    it 'calls Bunny service with specific config' do
      expect(Bunny).to receive(:new).with(example_config)
      Mts::Connection.new(example_config).connection
    end
    it 'calls Bunny service only once' do
      expect(Bunny).to receive(:new).and_return({})
        .once.with(example_config)
      conn = Mts::Connection.new(example_config)
      2.times do
        conn.connection
      end
    end
  end
end
