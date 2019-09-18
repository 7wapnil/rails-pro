# frozen_string_literal: true

describe Exchanger::Apis::CoinApi do
  subject { described_class.call('EUR', %w[BTC ETH MBTC TBTC]) }

  let(:expected_route) do
    'https://rest.coinapi.io/v1/exchangerate/EUR?'\
    'filter_asset_id=BTC,ETH,MBTC,TBTC'
  end

  let(:m_btc) { ::Payments::Crypto::SuppliedCurrencies::M_TBTC }
  let(:btc) { ::Payments::Crypto::SuppliedCurrencies::BTC }
  let(:expected_response) do
    { asset_id_base: 'EUR',
      rates: [
        { asset_id_quote: 'BTC', rate: 0.0001 },
        { asset_id_quote: 'ETH', rate: 1.5500 }
      ] }.to_json
  end

  let(:m_btc_rate) { subject.find { |rate| rate.code == m_btc } }
  let(:btc_rate) { subject.find { |rate| rate.code == btc } }

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

    expect(subject.count).to eq(2)
  end

  it 'returns empty list on empty response' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: '', headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.count).to be_zero
  end

  it 'returns empty list on error response' do
    stub_request(:get, expected_route)
      .to_return(status: 400, body: '', headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.count).to be_zero
  end

  it 'returns mBTC as calculated based on BTC' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: expected_response, headers: {
                   'content-type': 'application/json'
                 })

    expect(m_btc_rate.value).to eq(0.1)
  end

  it 'does not return BTC' do
    stub_request(:get, expected_route)
      .to_return(status: 200, body: expected_response, headers: {
                   'content-type': 'application/json'
                 })

    expect(btc_rate).to be_nil
  end
end
