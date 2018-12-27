describe Radar::BaseUofWorker do
  let(:xml) { '<_/>' }
  let(:parsed_xml) { {} }

  describe '.perform' do
    subject(:worker) { described_class.new }

    let(:subject_worker) { described_class.new }

    let(:handler_instance) { instance_double('SomeFeedHandler', handle: true) }
    let(:handler) do
      instance_double('SomeFeedHandler', new: handler_instance)
    end

    it { expect(described_class).to be < ApplicationWorker }

    context 'without worker_class defined' do
      it 'raises NotImplementedError' do
        expect { worker.perform(xml, 0) }.to raise_error(NotImplementedError)
      end
    end

    context 'with correct worker_class defined' do
      before do
        allow(subject_worker).to receive(:worker_class).and_return(handler)
        allow(XmlParser).to receive(:parse).and_return(parsed_xml)
        subject_worker.perform(xml, 0)
      end

      it 'parses payload with correct parser' do
        expect(XmlParser).to have_received(:parse).with(xml).once
      end

      it 'initializes worker_class with parsed data' do
        expect(handler).to have_received(:new).with(parsed_xml).once
      end

      it 'calls handle on defined worker_class' do
        expect(handler_instance).to have_received(:handle).once
      end
    end

    context 'with broken worker_class' do
      let(:error_message) { Faker::Lorem.paragraph }
      let!(:broken_handler) do
        handler = instance_double('BrokenFeedHandler')
        allow(handler).to receive(:new).and_raise(StandardError, error_message)
        handler
      end

      before do
        allow(
          subject_worker
        ).to receive(:worker_class).and_return(broken_handler)
        allow(Rails.logger).to receive(:error)
        subject_worker.perform(xml, 0)
      rescue StandardError
        StandardError
      end

      it 'raises an error back so that the worker fails' do
        expect { subject_worker.perform(xml, 0) }
          .to raise_error(StandardError, error_message)
      end
    end
  end
end
