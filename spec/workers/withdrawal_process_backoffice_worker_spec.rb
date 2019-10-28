describe WithdrawalProcessBackofficeWorker do
  it 'calls WalletEntry::Service with received argument' do
    entry_request = create(:entry_request)

    expect(WalletEntry::AuthorizationService)
      .to receive(:call).with(entry_request)
    described_class.new.perform(entry_request.id)
  end
end
