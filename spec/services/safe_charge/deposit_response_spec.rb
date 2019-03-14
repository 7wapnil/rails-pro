describe SafeCharge::DepositResponse do
  let(:secret_key) { Faker::Internet.password(30) }

  let(:transaction_status_code) { SafeCharge::Statuses::OK }
  let(:transaction_time_at) { Faker::Time.backward(10) }
  let(:transaction_time_at_formatted) do
    transaction_time_at.strftime('%Y-%m-%d.%T')
  end
  let(:transaction_id) { Faker::Number.number(9) }
  let(:transaction_status) { SafeCharge::Statuses::APPROVED }
  let(:total_amount) { entry_request.amount }
  let(:currency_code) { entry_request.currency.code }
  let(:product_id) { entry_request.id.to_s }

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
    create(:entry_request,
           kind: EntryRequest::DEPOSIT,
           status: EntryRequest::INITIAL)
  end

  before do
    # allow(ENV).to receive(:[])
    #   .with('SAFECHARGE_SECRET_KEY').and_return(secret_key)
    ENV['SAFECHARGE_SECRET_KEY'] = secret_key
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

    context 'with no parameters mismatch' do
      it 'raises no exception' do
        expect { verification_result }
          .not_to raise_error(SafeCharge::CallbackDataMismatch)
      end
    end

    # In the following examples data is changed on our side,
    # because the process of checksum calculation and comparison
    # is quite hard to intrude and alter

    context 'with callback amount mismatching entry_request' do
      it 'raises SafeCharge::CallbackDataMismatch' do
        entry_request.update(amount: params['totalAmount'] / 2.0)
        expect { verification_result }
          .to raise_error(SafeCharge::CallbackDataMismatch)
      end
    end

    context 'with callback currency code mesmatching entry_request currency' do
      it 'raises SafeCharge::CallbackDataMismatch' do
        entry_request.currency.update(code: params['currency'] + '_')
        expect { verification_result }
          .to raise_error(SafeCharge::CallbackDataMismatch)
      end
    end
  end
end
