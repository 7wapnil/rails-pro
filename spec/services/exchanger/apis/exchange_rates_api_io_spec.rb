describe Exchanger::Apis::ExchangeRatesApiIo do
  subject { described_class.new('EUR', %w[USD GBP]) }

  let(:expected_route) do
    "https://api.exchangeratesapi.io/latest?base=EUR&symbols=USD,GBP"
  end
  let(:expected_response) do
    { rates: {
      'USD': 1.13000,
      'GBP': 1.5500
    } }.to_json
  end

  before do
    create(:currency, :primary, code: Currency::PRIMARY_CODE)
    create(:currency, code: 'USD', kind: Currency::FIAT)
    create(:currency, code: 'GBP', kind: Currency::FIAT)
  end

  it 'requests rates from service' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: expected_response, headers: {
        'content-type': 'application/json'
      })

    expect(subject.call.count).to eq(2)
  end

  it 'returns empty list on empty response' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: '', headers: {
        'content-type': 'application/json'
      })

    expect(subject.call.count).to be_zero
  end

  it 'returns empty list on error response' do
    stub_request(:get, expected_route)
      .to_return(status: 550, body: '', headers: {
        'content-type': 'application/json'
      })

    expect(subject.call.count).to be_zero
  end
end
