describe SafeCharge::Response do
  let(:secret_key) { Faker::Internet.password(30) }

  let(:transaction_status_code) { SafeCharge::Statuses::OK }
  let(:transaction_time_at) { Faker::Time.backward(10) }
  let(:transaction_time_at_formatted) do
    transaction_time_at.strftime('%Y-%m-%d.%T')
  end
  let(:transaction_id) { Faker::Number.number(9) }
  let(:transaction_status) { SafeCharge::Statuses::APPROVED }
  let(:entry_request) { create(:entry_request) }
  let(:total_amount) { entry_request.amount }
  let(:currency_code) { entry_request.currency.code }
  let(:product_id) { entry_request.id }

  let(:correct_checksum) do
    checksum_string = [
      secret_key,
      total_amount,
      currency_code,
      transaction_time_at_formatted,
      transaction_id,
      transaction_status,
      product_id
    ].join

    Digest::SHA256.hexdigest(checksum_string)
  end

  let(:params) do
    {
      'ppp_status' => transaction_status_code,
      'totalAmount' => total_amount,
      'currency' => currency_code,
      'responseTimeStamp' => transaction_time_at_formatted,
      'PPP_TransactionID' => transaction_id.to_s,
      'Status' => transaction_status,
      'productId' => product_id,
      'advanceResponseChecksum' => correct_checksum
    }
  end

  describe '#approved?' do
    subject(:check) { described_class.new(params).approved? }

    it 'returns true for ok request and status approved' do
      params['ppp_status'] = SafeCharge::Statuses::OK
      params['Status'] = SafeCharge::Statuses::APPROVED
      expect(check).to be_truthy
    end

    it 'returns false for failed request' do
      params['ppp_status'] = SafeCharge::Statuses::FAIL
      params['Status'] = SafeCharge::Statuses::PENDING
      expect(check).to be_falsey
    end

    it 'returns true for ok request and status pending' do
      params['ppp_status'] = SafeCharge::Statuses::OK
      params['Status'] = SafeCharge::Statuses::PENDING
      expect(check).to be_falsey
    end
  end

  describe '#pending?' do
    subject(:check) { described_class.new(params).pending? }

    it 'returns true for ok request and status pending' do
      params['ppp_status'] = SafeCharge::Statuses::OK
      params['Status'] = SafeCharge::Statuses::PENDING
      expect(check).to be_truthy
    end

    it 'returns false for failed request' do
      params['ppp_status'] = SafeCharge::Statuses::FAIL
      params['Status'] = SafeCharge::Statuses::PENDING
      expect(check).to be_falsey
    end

    it 'returns true for ok request and status approved' do
      params['ppp_status'] = SafeCharge::Statuses::OK
      params['Status'] = SafeCharge::Statuses::APPROVED
      expect(check).to be_falsey
    end
  end
end
