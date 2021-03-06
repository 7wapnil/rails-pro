# frozen_string_literal: true

describe EntryRequests::RollbackWorker do
  it_behaves_like 'EntryRequest worker' do
    let(:service_class) { EntryRequests::ProcessingService }
  end
end
