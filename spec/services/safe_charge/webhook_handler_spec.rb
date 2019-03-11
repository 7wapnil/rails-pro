describe SafeCharge::WebhookHandler do
  let(:webhook_checksum) { SecureRandom.hex(10) }
  let(:service_call) { described_class.call(params) }
  let!(:entry_request) { create(:entry_request) }
  let(:params) do
    {
      'ppp_status' => SafeCharge::Statuses::OK,
      'Status' => SafeCharge::Statuses::APPROVED,
      'advanceResponseChecksum' => webhook_checksum,
      'productId' => entry_request.id,
      'payment_method' => SafeCharge::PaymentMethods::CC_CARD,
      'PPP_TransactionID' => Faker::Number.number(10).to_s
    }
  end

  before do
    allow(Digest::SHA256).to receive(:hexdigest).and_return(webhook_checksum)
  end

  context 'webhook authentication' do
    let(:auth_error) { SafeCharge::DmnAuthenticationError }

    it 'raises DmnAuthenticationError when checksum do not match' do
      allow(Digest::SHA256).to receive(:hexdigest).and_return('checksum')

      expect { service_call }.to raise_error auth_error
    end

    it 'do not raise error when checksum match' do
      expect { service_call }.not_to raise_error auth_error
    end
  end

  it 'sets request status to succeeded if webhook status is Approved' do
    params['Status'] = SafeCharge::Statuses::APPROVED
    service_call
    expect(entry_request.reload).to be_succeeded
  end

  it 'sets entry request status to pending if webhook status is pending' do
    params['Status'] = SafeCharge::Statuses::PENDING
    service_call

    expect(entry_request.reload).to be_pending
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
