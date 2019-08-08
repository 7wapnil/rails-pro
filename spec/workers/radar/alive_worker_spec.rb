# frozen_string_literal: true

describe Radar::AliveWorker do
  let(:worker) { described_class.new }
  let(:product) { create(:producer) }
  let(:timestamp) { (Time.zone.now.to_f * 1000).to_i }

  let(:payload) do
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'\
     "<alive product=\"#{product.id}\" "\
     "timestamp=\"#{timestamp}\" subscribed=\"1\"/>"
  end

  before do
    allow(Rails.logger).to receive(:info)
    allow_any_instance_of(::Radar::AliveWorker)
      .to receive(:job_id)
      .and_return(123)
    worker.perform(payload)
  end

  it 'logs extra data' do
    expect(Rails.logger)
      .to receive(:error)
      .with(
        hash_including(
          producer_id: product.id,
          producer_subscription_state: product.subscribed?,
          message_subscription_state: true
        )
      )

    subject.log_job_failure(StandardError)
  end

  it 'logs extra data when job is done' do
    expect(Rails.logger)
      .to have_received(:info)
      .with(
        hash_including(
          producer_id: product.id,
          producer_subscription_state: product.subscribed?,
          message_subscription_state: true
        )
      )
  end
end
