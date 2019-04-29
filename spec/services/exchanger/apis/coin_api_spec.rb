describe Exchanger::Apis::CoinApi do
  subject { described_class.new('EUR', %w[BTC ETH MBTC]) }

  let(:expected_route) do
    'https://rest.coinapi.io/v1/exchangerate/EUR?filter_asset_id=BTC,ETH,MBTC'
  end
  let(:expected_response) do
    { asset_id_base: 'EUR',
      rates: [
        { asset_id_quote: 'BTC', rate: 1.13000 },
        { asset_id_quote: 'ETH', rate: 1.5500 }
      ] }.to_json
  end

  before do
    create(:currency, :primary, code: Currency::PRIMARY_CODE)
    create(:currency, code: 'BTC', kind: Currency::CRYPTO)
    create(:currency, code: 'ETH', kind: Currency::CRYPTO)
    create(:currency, code: 'mBTC', kind: Currency::CRYPTO)
  end

  it 'requests rates from service' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: expected_response, headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.call.count).to eq(3)
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
      .to_return(status: 400, body: '', headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.call.count).to be_zero
  end

  it 'returns mBTC as calculated based on BTC' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: expected_response, headers: {
                   'content-type': 'application/json'
                 })

    mbtc = subject.call.detect { |rate| rate.code == 'mBTC' }
    expect(mbtc.value).to eq(1130)
  end
end
