describe Mts::MtsDecimal do
  EXAMPLES = [
    { input: 1, mts_decimal: 10_000 },
    { input: 1.0, mts_decimal: 10_000 },
    { input: 1.2345, mts_decimal: 12_345 },
    { input: 12_345.12345, mts_decimal: 123_451_235 },
    { input: 0.0001, mts_decimal: 1 },
    { input: '1.0', mts_decimal: 10_000 },
    { input: '1.2345', mts_decimal: 12_345 },
    { input: '12345.12345', mts_decimal: 123_451_235 },
    { input: '0.0001', mts_decimal: 1 }
  ].freeze

  describe '#from_number' do
    EXAMPLES.each do |ex|
      it "converts from #{ex[:input]} to #{ex[:mts_decimal]}" do
        expect(described_class.from_number(ex[:input]))
          .to eq(ex[:mts_decimal])
      end
    end

    it 'raises ArgumentError for under min value' do
      expect { described_class.from_number(0) }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError for over max value' do
      expect { described_class.from_number(described_class::MAX_VALUE + 1) }
        .to raise_error(ArgumentError)
    end
  end
end
