# frozen_string_literal: true

shared_examples 'EntryRequest worker' do
  let(:entry_request) { create(:entry_request) }
  let(:worker_service_class) { service_class }

  before { allow(worker_service_class).to receive(:call) }

  it 'calls respective service with passed entry request' do
    described_class.new.perform(entry_request.id)

    expect(worker_service_class)
      .to have_received(:call)
      .with(entry_request: entry_request)
  end
end
