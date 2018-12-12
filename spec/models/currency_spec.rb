describe Currency do
  it { should have_many(:entry_currency_rules) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }

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
end
