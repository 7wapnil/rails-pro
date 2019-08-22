# frozen_string_literal: true

describe Radar::OddsChangeWorker do
  let(:worker) { described_class.new }
  let(:external_id) { 'sr:match:1234' }
  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:event) do
    create(:event,
           external_id: external_id,
           remote_updated_at: nil,
           producer: prematch_producer)
  end
  let(:message_producer_id) { liveodds_producer.id }
  let(:template) { create(:market_template) }
  let(:specifiers) { 'hcp=1:0' }
  let(:market) do
    create(
      :market,
      event: event,
      external_id: "#{external_id}:#{template.external_id}/#{specifiers}",
      template: template,
      template_specifiers: specifiers
    )
  end
  let(:payload) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <odds_change product="#{message_producer_id}" event_id="#{external_id}" timestamp="#{Time.now.to_i}" request_id="1564727279">
        <odds>
          <market status="-2" id="#{template.external_id}" specifiers="#{market.template_specifiers}"/>
        </odds>
      </odds_change>
    XML
  end

  before do
    allow(Rails.logger).to receive(:warn)
    allow_any_instance_of(described_class)
      .to receive(:job_id)
      .and_return(123)
    worker.perform(payload)
  end

  it 'logs extra data on non-prematch nahdover' do
    expect(Rails.logger)
      .to receive(:error)
      .with(
        hash_including(
          event_id: external_id,
          event_producer_id: prematch_producer.id,
          message_producer_id: liveodds_producer.id
        )
      ).once
    subject.log_job_failure(StandardError)
  end
end
