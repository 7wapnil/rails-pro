describe EventCompetitor do
  it { is_expected.to belong_to(:event) }
  it { is_expected.to belong_to(:competitor) }

  context 'importation' do
    let!(:record) { create(:event_competitor) }

    it 'ignores duplications' do
      described_class.create_or_ignore_on_duplicate(record)
      expect(described_class.count).to eq(1)
    end
  end
end
