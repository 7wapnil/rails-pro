# frozen_string_literal: true

describe EntryRequests::WithdrawalWorker do
  it_behaves_like 'EntryRequest worker' do
    let(:service_class) { EntryRequests::WithdrawalService }
  end
end
