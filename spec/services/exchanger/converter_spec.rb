# frozen_string_literal: true

describe Exchanger::Converter do
  before do
    create(:currency, code: Currency::PRIMARY_CODE, exchange_rate: nil)
    create(:currency, code: 'USD', exchange_rate: 1.13000)
    create(:currency, code: 'GBP', exchange_rate: 0.86390)
    create(:currency, code: 'BTC', exchange_rate: 0.00022)
    create(:currency, code: 'ETH', exchange_rate: 0.00500)
  end

  [
    # Simple conversion to base currency
    { value: 10, origin: 'USD', target: 'EUR', expected: 8.8495 },
    { value: 10, origin: 'GBP', target: 'EUR', expected: 11.5754 },
    { value: 10, origin: 'BTC', target: 'EUR', expected: 45_454.5454 },
    { value: 10, origin: 'ETH', target: 'EUR', expected: 2000 },

    # Conversion between currencies
    { value: 10, origin: 'USD', target: 'GBP', expected: 7.6451 },
    { value: 10, origin: 'EUR', target: 'GBP', expected: 8.63900 },

    # If only I bought it in 2014
    { value: 50, origin: 'BTC', target: 'EUR', expected: 227_272.7272 }

  ].each do |test_data|

    it "converts '#{test_data[:origin]}' to '#{test_data[:target]}'" do
      result = described_class.call(test_data[:value],
                                    test_data[:origin],
                                    test_data[:target])

      expect(result).to(
        eq(test_data[:expected].truncate(described_class::PRECISION))
      )
    end
  end

  it 'returns initial value if conversion currencies are similar' do
    value = 1234.1234
    expect(described_class.call(value, 'EUR', 'EUR')).to(
      eq(value.truncate(described_class::PRECISION))
    )
  end
end
