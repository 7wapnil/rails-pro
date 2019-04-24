describe CompetitorPlayer do
  it { is_expected.to belong_to(:competitor) }
  it { is_expected.to belong_to(:player) }

  context 'importation' do
    let!(:record) { create(:competitor_player) }

    it 'ignores duplications' do
      described_class.create_or_ignore_on_duplicate(record)
      expect(described_class.count).to eq(1)
    end
  end
end
