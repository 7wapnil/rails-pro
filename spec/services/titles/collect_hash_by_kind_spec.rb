describe Titles::CollectHashByKind do
  let!(:e1) { create :title, kind: :esports, position: 0 }
  let!(:e2) { create :title, kind: :esports, position: 1 }
  let!(:e3) { create :title, kind: :esports, position: 2 }
  let!(:s1) { create :title, kind: :sports,  position: 0 }
  let!(:s2) { create :title, kind: :sports,  position: 1 }
  let!(:s3) { create :title, kind: :sports,  position: 2 }

  it 'returns expected hash' do
    expect(described_class.call).to include(
      'esports' => Title.esports.order(:position),
      'sports'  => Title.sports.order(:position)
    )
  end
end
