# frozen_string_literal: true

describe Exchanger::Apis::CryptoRatesApi do
  subject { described_class.call('EUR', %w[mBTC ETH BTC]) }

  let(:btc_expected_route) { 'https://api.cryptonator.com/api/ticker/EUR-BTC' }
  let(:eth_expected_route) { 'https://api.cryptonator.com/api/ticker/EUR-ETH' }
  let(:price) { '0.001123' }

  let(:m_btc) { ::Payments::Crypto::SuppliedCurrencies::M_BTC }
  let(:t_m_btc) { ::Payments::Crypto::SuppliedCurrencies::M_TBTC }
  let(:btc) { ::Payments::Crypto::SuppliedCurrencies::BTC }
  let(:btc_expected_response) do
    {
      'ticker' => {
        'target' => 'BTC',
        'price' => price
      },
      'success' => true
    }.to_json
  end
  let(:eth_expected_response) do
    {
      'ticker' => {
        'target' => 'ETH',
        'price' => price
      },
      'success' => true
    }.to_json
  end

  let(:m_btc_rate) { subject.find { |rate| rate.code == m_btc } }
  let(:t_m_btc_rate) { subject.find { |rate| rate.code == t_m_btc } }
  let(:btc_rate) { subject.find { |rate| rate.code == btc } }

  before do
    create(:currency, :primary, code: Currency::PRIMARY_CODE)
    create(:currency, code: 'ETH', kind: Currency::CRYPTO)
    create(:currency, code: 'mBTC', kind: Currency::CRYPTO)

    stub_request(:get, btc_expected_route)
      .to_return(status: 200, body: btc_expected_response, headers: {
                   'content-type': 'application/json'
                 })

    stub_request(:get, eth_expected_route)
      .to_return(status: 200, body: eth_expected_response, headers: {
                   'content-type': 'application/json'
                 })
  end

  it 'requests rates from service' do
    expect(subject.count).to eq(3)
  end

  it 'updates test BTC for development environment' do
    expect(t_m_btc_rate.value).to eq(m_btc_rate.value)
  end

  it 'does not update test BTC for production environment' do
    stub_const(
      'Payments::Crypto::CoinsPaid::Currency::COINSPAID_MODE',
      'production'
    )

    expect(t_m_btc_rate).to be_nil
  end

  it 'returns empty list on empty response' do
    stub_request(:get, btc_expected_route)
      .to_return(status: 200, headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.count).to be_zero
  end

  it 'returns empty list on error response' do
    stub_request(:get, btc_expected_route)
      .to_return(status: 400, body: '', headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.count).to be_zero
  end

  it 'returns empty list on unsuccessful response' do
    stub_request(:get, btc_expected_route)
      .to_return(status: 200, body: { 'success' => false }.to_json, headers: {
                   'content-type': 'application/json'
                 })

    expect(subject.count).to be_zero
  end

  it 'returns mBTC as calculated based on BTC' do
    expect(m_btc_rate.value).to eq(price.to_f * 1000)
  end

  it 'does not return BTC' do
    expect(btc_rate).to be_nil
  end
end
