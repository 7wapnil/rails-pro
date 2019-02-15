# frozen_string_literal: true

describe EntryRequests::WithdrawWorker do
  it_behaves_like 'EntryRequest worker' do
    let(:service_class) { Withdrawals::WithdrawalService }
  end
end
