describe OddsFeed::Radar::EventAdapter::TitleSelector do
  subject { described_class.call(payload: payload) }

  let(:id)      { Faker::Internet.user_name }
  let(:name)    { Faker::GameOfThrones.name }
  let(:payload) { { 'id' => id, 'name' => name } }

  context 'found title' do
    context 'by id' do
      let!(:title) do
        create(:title, external_id: id, external_name: 'Another name')
      end

      it { expect(subject).to eq(title) }
    end

    context 'by name' do
      let!(:title) do
        create(:title, external_id: 'Another id', external_name: name)
      end

      it { expect(subject).to eq(title) }
    end
  end

  it 'new title' do
    expect { subject }.to change(Title, :count).by(1)
  end
end
