describe Currency do
  it { is_expected.to have_many(:entry_currency_rules) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:code) }

  describe '.primary' do
    context 'with existing primary currency' do
      let!(:currency) { create(:currency, :primary) }

      it 'returns primary currency' do
        expect(described_class.primary).to eq(currency)
      end
    end

    context 'without primary currency' do
      it 'returns nil' do
        expect(described_class.primary).to be_nil
      end
    end
  end

  describe '.cached_all' do
    subject(:currency) { create(:currency) }

    before do
      allow(described_class).to receive(:all)
      described_class.flush_cache
    end

    it 'caches multiple calls' do
      2.times { described_class.cached_all }
      expect(described_class).to have_received(:all).once
    end

    it 'flush cache on commit' do
      described_class.cached_all
      currency.update(code: Faker::Currency.code)
      described_class.cached_all
      expect(described_class).to have_received(:all).twice
    end
  end
end
