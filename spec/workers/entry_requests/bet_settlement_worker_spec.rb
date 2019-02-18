# frozen_string_literal: true

describe EntryRequests::BetSettlementWorker do
  it_behaves_like 'EntryRequest worker' do
    let(:service_class) { EntryRequests::BetSettlementService }
  end
end
