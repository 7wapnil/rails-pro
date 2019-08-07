describe Payments::Fiat::Wirecard::Payouts::RequestHandler do
  subject { described_class.call(transaction) }

  let(:transaction) do
    transaction_class.new(
      id: id,
      method: payment_method,
      customer: customer,
      currency_code: currency.code,
      amount: amount,
      withdrawal: withdrawal,
      details: {
        'masked_account_number' => card_mask,
        'token_id' => card_token
      }
    )
  end
  let(:id) { entry_request.id }
  let(:customer) { create(:customer) }
  let(:entry_request) do
    create(:entry_request, customer: customer, currency: currency)
  end
  let(:currency) { create(:currency, :primary) }
  let(:wallet) { create(:wallet, currency: currency) }
  let(:entry) do
    create(:entry, kind: Entry::WITHDRAW, amount: amount, wallet: wallet)
  end
  let(:withdrawal) { create(:withdrawal, entry_request: entry_request) }
  let(:amount) { entry_request.amount }
  let(:payment_method) { Payments::Methods::CREDIT_CARD }
  let(:transaction_class) { Payments::Transactions::Payout }
  let(:card_mask) { Faker::Number.number(16).to_s }
  let(:card_token) { SecureRandom.hex(27) }

  let(:response_body) do
    {
      'payment' => {
        'statuses' => {
          'status' => [
            { 'code' => code, 'description' => code_description }
          ]
        }
      }
    }
  end
  let(:code) { 201 }
  let(:code_description) { 'Created' }

  let(:request) do
    instance_double(
      HTTParty::Response,
      code: 201,
      body: response_body.to_json
    )
  end
  let(:url) { 'https://host.com?some_params' }

  before do
    # ignore job after new customer creating
    allow(Customers::Summaries::UpdateWorker).to receive(:perform_async)
  end

  context 'when request completed' do
    before do
      allow(Payments::Fiat::Wirecard::Client)
        .to receive(:post)
        .and_return(request)
    end

    it { is_expected.to be_nil }
  end

  context 'when something went wrong' do
    before do
      allow(Payments::Fiat::Wirecard::Client)
        .to receive(:post)
        .and_raise(HTTParty::ResponseError, request)
    end

    let(:code) { 400 }
    let(:code_description) { 'Error message' }

    it 'raise payment error' do
      expect { subject }.to raise_error(Withdrawals::PayoutError)
    end

    it 'rollback withdrawal status' do
      subject
    rescue Withdrawals::PayoutError => _e
      expect(withdrawal.status).to eq(Withdrawal::PENDING)
    end
  end
end
