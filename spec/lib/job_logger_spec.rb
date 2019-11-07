describe JobLogger do
  let(:dummy_class) { Class.new { extend JobLogger } }
  let(:job_id) { Faker::Internet.password(13, 13, false, false) }
  let(:logger_double) { instance_double('Logger', send: true) }
  let(:logger_level) { %i[info debug fatal error].sample }
  let(:message) { Faker::Lorem.sentence }
  let(:error_message) { Faker::Lorem.sentence }
  let(:error) { StandardError.new(error_message) }

  let(:enqueued_at) { Faker::Time.backward(1).to_datetime }
  let(:start_time) { (enqueued_at + 1.hour).to_f }
  let(:current_time) { Time.zone.now.to_datetime }

  before do
    allow(dummy_class).to receive(:job_id) { job_id }
    allow(dummy_class).to receive(:enqueued_at) { enqueued_at }
    allow(dummy_class).to receive(:start_time) { start_time }
    allow(Rails).to receive(:logger) { logger_double }
  end

  include_context 'frozen_time'

  describe '#log_job_failure' do
    before { allow(dummy_class).to receive(:log_job_message) }

    context 'with Error passed' do
      before { dummy_class.log_job_failure(error) }

      it 'calls log_job_message with predefined level and message' do
        expect(dummy_class).to have_received(:log_job_message)
          .with(:error, message: error_message, error_object: error).once
      end
    end

    context 'with message passed' do
      before { dummy_class.log_job_failure(error) }

      it 'calls log_job_message with predefined level and message' do
        expect(dummy_class).to have_received(:log_job_message)
          .with(:error, message: error_message, error_object: error).once
      end
    end
  end

  describe 'protected #log_job_message' do
    let(:payload_hash) { { foo: :bar, boo: :baz } }
    let(:default_expectation_arguments) do
      {
        jid:          job_id,
        class_name:   dummy_class.class.name,
        current_time: Time.zone.now.to_datetime,
        thread_id:    Thread.current.object_id
      }
    end

    context 'when job_id is not available and payload is a simple message' do
      before do
        allow(dummy_class).to receive(:job_id).and_return(nil)
        dummy_class.send(:log_job_message, logger_level, message)
      end

      it 'calls simple logger' do
        expect(logger_double).to have_received('send')
          .with(logger_level, message).once
      end
    end

    context 'when job_id is not available and payload is a hash' do
      before do
        allow(dummy_class).to receive(:job_id).and_return(nil)
        dummy_class.send(:log_job_message, logger_level, payload_hash)
      end

      it 'calls simple logger' do
        expect(logger_double).to have_received('send')
          .with(logger_level, payload_hash).once
      end
    end

    context 'when job_id is available and payload is a message' do
      before do
        dummy_class.send(:log_job_message, logger_level, message)
      end

      it 'calls extended logger' do
        arguments =
          default_expectation_arguments.merge(message: message)
        expect(logger_double)
          .to have_received('send')
          .with(logger_level, **arguments).once
      end
    end

    context 'when job_id is available and payload is a hash' do
      before do
        dummy_class.send(:log_job_message, logger_level, payload_hash)
      end

      it 'calls extended logger' do
        arguments =
          default_expectation_arguments.merge(payload_hash)
        expect(logger_double)
          .to have_received('send')
          .with(logger_level, **arguments).once
      end
    end
  end

  describe 'protected #log_success' do
    let(:success_message) do
      "#{dummy_class.class.name} successfully finished a job"
    end

    before do
      allow(dummy_class).to receive(:log_process)
      dummy_class.send(:log_success)
    end

    it 'calls log_process with predefined level and message' do
      expect(dummy_class).to have_received(:log_process)
        .with(:info, success_message).once
    end
  end

  describe 'protected #log_failure' do
    before do
      allow(dummy_class).to receive(:log_process)
      dummy_class.send(:log_failure, error)
    end

    it 'calls log_process with predefined level and error message' do
      expect(dummy_class).to have_received(:log_process)
        .with(:error, error_message, error_object: error).once
    end
  end

  describe 'private #log_process' do
    let(:job_performing_time) do
      (current_time.to_f - enqueued_at.to_f).round(3)
    end
    let(:job_execution_time) { (current_time.to_f - start_time).round(3) }
    let(:overall_processing_time) do
      (current_time.to_f - enqueued_at.to_f +
        current_time.to_f - start_time).round(3)
    end

    before do
      dummy_class.send(:log_process, logger_level, message)
    end

    it 'calls complex computations' do
      expect(logger_double)
        .to have_received('send')
        .with(logger_level,
              jid:                     job_id,
              worker:                  dummy_class.class.name,
              message:                 message,
              current_time:            current_time,
              job_enqueued_at:         enqueued_at,
              job_performing_time:     job_performing_time,
              job_execution_time:      job_execution_time,
              overall_processing_time: overall_processing_time,
              thread_id:               Thread.current.object_id,
              event_id:                Thread.current[:event_id],
              message_producer_id:     Thread.current[:message_producer_id],
              message_timestamp:       Thread.current[:message_timestamp],
              event_producer_id:       Thread.current[:event_producer_id]).once
    end

    # TODO: Missing parts
    xit 'log_thread_info_missing corner cases'
    xit 'start_time corner cases'
    xit 'performing_time corner cases'
  end
end
