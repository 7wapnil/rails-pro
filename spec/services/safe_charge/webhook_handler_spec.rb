describe SafeCharge::WebhookHandler do
  let(:webhook_checksum) { SecureRandom.hex(10) }
  let(:service_call) { described_class.call(params) }
  let(:entry_request) { create(:entry_request) }
  let(:ratio) { 0.75 }
  let!(:real_money_balance_entry_request) do
    create(:balance_entry_request, kind: Balance::REAL_MONEY,
                                   amount: entry_request.amount * ratio,
                                   entry_request: entry_request)
  end
  let(:entry_currency_rule) { create(:entry_currency_rule) }
  let(:params) do
    {
      'ppp_status' => SafeCharge::Statuses::OK,
      'Status' => SafeCharge::Statuses::APPROVED,
      'advanceResponseChecksum' => webhook_checksum,
      'currency' => entry_request.currency.code,
      'totalAmount' => real_money_balance_entry_request.amount.to_s,
      'productId' => entry_request.id.to_s,
      'payment_method' => SafeCharge::PaymentMethods::CC_CARD,
      'PPP_TransactionID' => Faker::Number.number(10).to_s
    }
  end

  before do
    allow(Digest::SHA256).to receive(:hexdigest).and_return(webhook_checksum)
    entry_request.currency.save!
    allow(EntryCurrencyRule)
      .to receive('find_by!')
      .and_return(entry_currency_rule)
  end

  include_context 'base_currency'

  context 'webhook authentication' do
    let(:auth_error) { SafeCharge::DmnAuthenticationError }

    it 'raises DmnAuthenticationError when checksum do not match' do
      allow(Digest::SHA256).to receive(:hexdigest).and_return('checksum')

      expect { service_call }.to raise_error(auth_error)
    end

    it 'do not raise error when checksum match' do
      expect { service_call }.not_to raise_error
    end
  end

  it 'sets request status to succeeded if webhook status is Approved' do
    params['Status'] = SafeCharge::Statuses::APPROVED
    service_call
    expect(entry_request.reload).to be_succeeded
  end

  it 'does not change entry request status when webhook status is pending' do
    params['ppp_status'] = SafeCharge::Statuses::PENDING
    params['Status'] = SafeCharge::Statuses::PENDING

    expect { service_call }
      .not_to(change { entry_request.reload.status })
  end

  it "sets entry request status to 'failed' when ppp_status is 'FAIL'" do
    params['ppp_status'] = SafeCharge::Statuses::FAIL
    service_call

    expect(entry_request.reload).to be_failed
  end

  it "sets entry request status to 'failed' when status is not found" do
    params['Status'] = ''
    service_call

    expect(entry_request.reload).to be_failed
  end
end
