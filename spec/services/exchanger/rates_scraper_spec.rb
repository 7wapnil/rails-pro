describe Exchanger::RatesScraper do
  let(:fiat_rates) do
    [
      Exchanger::Apis::Rate.new('USD', 1.1305),
      Exchanger::Apis::Rate.new('GBP', 0.86390)
    ]
  end

  let(:crypto_rates) do
    [
      Exchanger::Apis::Rate.new('BTC', 0.00021714978246574915),
      Exchanger::Apis::Rate.new('ETH', 0.000117)
    ]
  end

  before do
    create(:currency, :primary, code: Currency::PRIMARY_CODE)
    create(:currency, code: 'USD', kind: Currency::FIAT)
    create(:currency, code: 'GBP', kind: Currency::FIAT)
    create(:currency, code: 'BTC', kind: Currency::CRYPTO)
    create(:currency, code: 'ETH', kind: Currency::CRYPTO)

    allow_any_instance_of(Exchanger::Apis::ExchangeRatesApiIo)
      .to receive(:call)
      .and_return(fiat_rates)

    allow_any_instance_of(Exchanger::Apis::CoinApi)
      .to receive(:call)
      .and_return(crypto_rates)
  end

  it 'updates fiat rates' do
    subject.call
    expect(::Currency.find_by(code: 'USD').exchange_rate).to eq(1.1305)
  end

  it 'updates crypto rates' do
    subject.call
    expect(::Currency.find_by(code: 'BTC').exchange_rate).to eq(0.00022)
  end
end
