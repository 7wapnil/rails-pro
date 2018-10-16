describe Mts::UofId do
  let(:title) { create(:title, external_id: 'sr:sport:110') }
  let(:event) { create(:event, title: title) }
  let(:market) { create(:market, event: event) }
  let(:odd) do
    create(:odd,
           market: market,
           external_id: 'sr:match:15868492:186/setnr=1|gamenr=2:4')
  end

  subject { described_class.new(odd) }

  describe '.uof_id' do
    it 'generates correct uof id' do
      expect(subject.uof_id).to eq 'uof:3/sr:sport:110/186/4?setnr=1&gamenr=2'
    end
  end
end