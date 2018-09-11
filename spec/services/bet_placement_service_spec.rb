describe BetPlacement::Service do
  let(:bet) { create(:bet) }

  subject { described_class.new(bet) }

  let(:bet_request) { subject.send(:entry_request) }

  it 'creates an entry request from bet' do
    expect(bet_request).to be_an EntryRequest
    expect(bet_request.amount).to eq(-bet.amount)
    expect(bet_request.currency).to eq bet.currency
    expect(bet_request.kind).to eq 'bet'
    expect(bet_request.mode).to eq 'sports_ticket'
    expect(bet_request.initiator).to eq bet.customer
    expect(bet_request.customer).to eq bet.customer
    expect(bet_request.origin).to eq bet
  end

  it 'calls WalletEntry::Service with entry request' do
    expect(WalletEntry::AuthorizationService)
      .to receive(:call).with(bet_request)
    subject.call
  end

  it 'updates bet status and message from request' do
    bet.update_attributes(status: nil, message: nil)

    subject.call

    expect(bet.status).to eq bet_request.status
    expect(bet.message).to eq bet_request.result_message
  end
end
