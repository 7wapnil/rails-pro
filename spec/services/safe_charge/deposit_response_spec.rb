describe SafeCharge::DepositResponse do
  let(:secret_key) { Faker::Internet.password(30) }

  let(:transaction_status_code) { SafeCharge::Statuses::OK }
  let(:transaction_time_at) { Faker::Time.backward(10) }
  let(:transaction_time_at_formatted) do
    transaction_time_at.strftime('%Y-%m-%d.%T')
  end
  let(:total_amount) { Faker::Number.decimal(2, 2) }
  let(:currency_code) { Faker::Currency.code }
  let(:transaction_id) { Faker::Number.number(9) }
  let(:transaction_status) { SafeCharge::Statuses::APPROVED }
  let(:product_id) do
    entry_request.id.to_s
  end

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

  let(:entry_request) do
    build_stubbed(:entry_request,
                  kind: EntryRequest::DEPOSIT,
                  status: EntryRequest::INITIAL)
  end

  before do
    allow(ENV).to receive(:[])
      .with('SAFECHARGE_SECRET_KEY').and_return(secret_key)
    allow(EntryRequest)
      .to receive(:find).with(entry_request.id).and_return(entry_request)
  end

  describe '#entry_request' do
    it 'returns entry request described in response' do
      expect(described_class.new(params).entry_request).to eq entry_request
    end
  end

  describe '#validate!' do
    subject(:verification_result) do
      described_class.new(params).validate!
    end

    it 'truthy on valid checksum' do
      expect(verification_result).to be_truthy
    end

    CHECKSUM_PARAMS =
      %w[totalAmount currency responseTimeStamp PPP_TransactionID
         Status productId advanceResponseChecksum].freeze
    CHECKSUM_PARAMS.each do |param|
      it "raise checksum vaildation error on corrupted #{param}" do
        params[param] = 'incorrect'
        expect { verification_result }
          .to raise_error(described_class::AUTHENTICATION_ERROR)
      end
    end

    context 'when entry request of invalid type referenced' do
      let(:entry_request) do
        build_stubbed(:entry_request,
                      kind: EntryRequest::WITHDRAW,
                      status: EntryRequest::INITIAL)
      end

      it 'raises type error' do
        expect { verification_result }
          .to raise_error(described_class::TYPE_ERROR)
      end
    end
  end
end
