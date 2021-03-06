# frozen_string_literal: true

describe EntryRequests::DepositWorker do
  it_behaves_like 'EntryRequest worker' do
    let(:service_class) { EntryRequests::DepositService }
  end
end
