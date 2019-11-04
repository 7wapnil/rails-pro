# frozen_string_literal: true

describe OddsFeed::Radar::Producers::RequestRecovery do
  subject { described_class.call(producer: producer) }

  let(:control_state) { ::Radar::Producer::HEALTHY }
  let(:last_subscribed_at) { 30.seconds.ago }
  let(:last_disconnected_at) { last_subscribed_at }
  let(:recovery_requested_at) { last_subscribed_at - 30.seconds }
  let(:producer) do
    create(
      :liveodds_producer,
      state: control_state,
      last_subscribed_at: last_subscribed_at,
      last_disconnected_at: last_disconnected_at,
      recovery_requested_at: recovery_requested_at
    )
  end

  let(:payload) do
    { 'response' => { 'response_code' => described_class::ACCEPTED } }
  end

  let(:node_id) { Faker::Number.number(4).to_i }
  let(:requested_at) { Time.zone.now }
  let(:request_id) { requested_at.to_i }

  before do
    allow_any_instance_of(described_class).to receive(:job_id).and_return(123)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with('RADAR_MQ_NODE_ID').and_return(node_id)
    allow(::Radar::Producer).to receive(:recovery_disabled?).and_return(false)
    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:product_recovery_initiate_request)
      .and_return(payload)
  end

  include_context 'frozen_time'

  it 'initiates recovery' do
    subject
    expect(producer.reload).to have_attributes(
      recovery_requested_at: requested_at,
      recovery_snapshot_id: request_id,
      recovery_node_id: node_id
    )
  end

  it 'sends a correct params to Bet Radar client' do
    expect_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:product_recovery_initiate_request)
      .with(
        product_code: producer.code,
        after: last_disconnected_at,
        node_id: node_id,
        request_id: request_id
      )
      .and_return(payload)
    subject
  end

  context 'when producer is already recovering' do
    let(:producer) { create(:liveodds_producer, :recovering) }

    it 'requests recovery from last recovery request' do
      expect_any_instance_of(::OddsFeed::Radar::Client)
        .to receive(:product_recovery_initiate_request)
        .with(hash_including(after: producer.recovery_requested_at))
        .and_return(payload)
      subject
    end
  end

  context 'when there is no last_disconnected_at specified' do
    let(:last_disconnected_at) {}

    it 'requests recovery from last subscription time' do
      expect_any_instance_of(::OddsFeed::Radar::Client)
        .to receive(:product_recovery_initiate_request)
        .with(hash_including(after: last_subscribed_at))
        .and_return(payload)
      subject
    end

    context 'and last_subscribed_at is not specified as well' do
      let(:last_subscribed_at) {}
      let(:recovery_requested_at) {}

      it 'requests recovery from approximate server shutdown time' do
        expect_any_instance_of(::OddsFeed::Radar::Client)
          .to receive(:product_recovery_initiate_request)
          .with(
            hash_including(
              after: described_class::TERMINATION_PROCESS_LENGTH.ago
            )
          )
          .and_return(payload)
        subject
      end
    end
  end

  context 'when recovery length is more than allowed' do
    let(:last_disconnected_at) do
      described_class::MAX_RECOVERY_LENGTH.ago - 5.minutes
    end

    it 'requests recovery with max allowed length' do
      expect_any_instance_of(::OddsFeed::Radar::Client)
        .to receive(:product_recovery_initiate_request)
        .with(
          hash_including(
            after: requested_at - described_class::MAX_RECOVERY_LENGTH
          )
        )
        .and_return(payload)
      subject
    end
  end

  it 'proceeds successfully' do
    expect(subject).to eq(true)
  end

  context 'when recovery is disabled' do
    before do
      allow(::Radar::Producer).to receive(:recovery_disabled?).and_return(true)
    end

    it 'logs an error' do
      expect(Rails.logger)
        .to receive(:error)
        .with(
          hash_including(
            message: 'Recovery is disabled',
            error_object: kind_of(RuntimeError),
            recovery_from: last_disconnected_at,
            node_id: node_id,
            request_id: request_id,
            recovery_requested_at: requested_at,
            last_recovery_call_at: recovery_requested_at,
            delay_between_recovery: (requested_at - recovery_requested_at).round
          )
        )
      subject
    end

    it 'fails' do
      expect(subject).to eq(false)
    end
  end

  context 'when request was rejected (response with error status code)' do
    let(:response_code) { 'BAD_REQUEST' }
    let(:error_message) do
      'ERROR. Bad Request: Timestamp too far in the past! ' \
      'Allowed is max 72 hours in the past'
    end

    let(:payload) do
      {
        'response' => {
          'action' => { '__content__' => 'Request for recovery' },
          'message' => { '__content__' => error_message },
          'response_code' => response_code
        }
      }
    end

    it 'logs an error' do
      expect(Rails.logger)
        .to receive(:error)
        .with(
          hash_including(
            message: 'Unsuccessful recovery',
            reason: error_message,
            response_status: response_code,
            error_object: kind_of(::Radar::UnsuccessfulRecoveryError),
            recovery_from: last_disconnected_at,
            node_id: node_id,
            request_id: request_id,
            recovery_requested_at: requested_at,
            last_recovery_call_at: recovery_requested_at,
            delay_between_recovery: (requested_at - recovery_requested_at).round
          )
        )
      subject
    end

    it 'fails' do
      expect(subject).to eq(false)
    end
  end

  context 'when limit exceeded (non-parsable response)' do
    let(:error_message) do
      'Code 403 - <?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
      '<response response_code="FORBIDDEN"><action>' \
      'Too many requests. Access forbidden. Limits are: 4 requests per' \
      '120 minutes(s)  [Recovery length: 1440 minutes], 2 requests per' \
      '30 minutes(s)  [Recovery length: 1440 minutes], 4 requests per' \
      '10 minutes(s)  [Recovery length: 30 minutes], 10 requests per' \
      '60 minutes(s)  [Recovery length: 30 minutes], 20 requests per' \
      '10 minutes(s) , 60 requests per 60 minutes(s) .</action>' \
      '<message>ERROR. Access forbidden.</message></response>'
    end

    before do
      allow_any_instance_of(::OddsFeed::Radar::Client)
        .to receive(:product_recovery_initiate_request)
        .and_raise(HTTParty::ResponseError, error_message)
    end

    it 'logs an error' do
      expect(Rails.logger)
        .to receive(:error)
        .with(
          hash_including(
            message: 'Unsuccessful recovery',
            reason: error_message,
            response_status: nil,
            error_object: kind_of(::Radar::UnsuccessfulRecoveryError),
            recovery_from: last_disconnected_at,
            node_id: node_id,
            request_id: request_id,
            recovery_requested_at: requested_at,
            last_recovery_call_at: recovery_requested_at,
            delay_between_recovery: (requested_at - recovery_requested_at).round
          )
        )
      subject
    end

    it 'fails' do
      expect(subject).to eq(false)
    end
  end

  context 'on AASM transition error' do
    before do
      allow(producer)
        .to receive(:initiate_recovery!)
        .and_raise(AASM::InvalidTransition)
    end

    it 'fails' do
      expect(subject).to eq(false)
    end
  end
end
