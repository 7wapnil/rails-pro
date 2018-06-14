describe EntryRequestProcessingJob do
  it 'calls WalletEntry::Service with received argument' do
    entry_request = build(:entry_request)

    expect(WalletEntry::Service).to receive(:call).with(entry_request)
    described_class.perform_now(entry_request)
  end
end
