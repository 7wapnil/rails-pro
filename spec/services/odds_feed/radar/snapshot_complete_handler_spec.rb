# frozen_string_literal: true

describe OddsFeed::Radar::SnapshotCompleteHandler do
  subject { described_class.new(payload).handle }

  let(:producer) { create(:producer, :recovering) }
  let(:payload_recovery_id) { producer.recovery_snapshot_id }

  let(:payload) do
    XmlParser.parse(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' \
        '<snapshot_complete ' \
        "request_id=\"#{payload_recovery_id}\" " \
        "timestamp=\"1234578\" product=\"#{producer.id}\"/>"
    )
  end

  it 'completes recovery' do
    subject
    expect(producer.reload).to have_attributes(
      state: ::Radar::Producer::HEALTHY,
      recovery_requested_at: nil,
      recovery_snapshot_id: nil,
      recovery_node_id: nil,
      last_disconnected_at: nil
    )
  end

  context 'on AASM transition error' do
    let(:producer) do
      create(:producer, :recovering, state: ::Radar::Producer::HEALTHY)
    end
    let(:error_message) do
      "Event 'complete_recovery' cannot transition from " \
      "'#{::Radar::Producer::HEALTHY}'."
    end

    it 'raises an error' do
      expect { subject }.to raise_error(AASM::InvalidTransition, error_message)
    end
  end

  context 'when snapshot id does not match' do
    let(:payload_recovery_id) { 0 }

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    it 'logs an error' do
      expect(Rails.logger)
        .to receive(:error)
        .with(
          hash_including(
            message: 'Out-dated snapshot completed',
            producer_id: producer.id,
            producer_state: producer.state,
            producer_request_id: producer.recovery_snapshot_id,
            payload_request_id: payload_recovery_id,
            error_object: kind_of(::Radar::UnknownSnapshotError)
          )
        )
      subject
    end
  end
end
