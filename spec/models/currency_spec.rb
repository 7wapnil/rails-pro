describe Currency do
  it { should have_many(:entry_currency_rules) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }

  describe '.primary_currency' do
    let(:subject) { described_class }

    context 'with existing primary currency' do
      let!(:currency) { create(:currency, primary: true) }

      it 'returns primary currency' do
        expect(subject.primary_currency).to eq(currency)
      end
    end

    context 'without primary currency' do
      it 'returns nil' do
        expect(subject.primary_currency).to be_nil
      end
    end
  end
end
