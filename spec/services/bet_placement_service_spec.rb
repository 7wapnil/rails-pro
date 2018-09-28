require 'services/service_spec'

describe BetPlacement::SubmissionService do
  let(:bet) { create(:bet) }

  subject { described_class.new(bet) }

  let(:bet_request) { subject.send(:entry_request) }

  it_behaves_like 'callable service'

  it 'creates an entry request from bet' do
    expect(bet_request).to be_an EntryRequest

    expect(bet_request)
      .to have_attributes(
        amount: -bet.amount,
        currency: bet.currency,
        kind: 'bet',
        mode: 'sports_ticket',
        initiator: bet.customer,
        customer: bet.customer,
        origin: bet
      )
  end

  it 'calls WalletEntry::Service with entry request' do
    expect(WalletEntry::AuthorizationService)
      .to receive(:call).with(bet_request)
    subject.call
  end

  it 'updates bet status and message from request on failure' do
    bet.update_attributes(status: Bet.statuses[:sent_to_internal_validation], message: :foo)

    subject.call

    expect(bet.status).to eq bet_request.status
    expect(bet.message).to eq bet_request.result_message
  end
end
