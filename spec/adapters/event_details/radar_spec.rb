describe ::EventDetails::Radar do
  subject { described_class.new(event) }

  let(:payload) do
    { competitors: {
      competitor: [
        { id: 'sr:competitor:405125', name: 'Melichar N / Peschke K' },
        { id: 'sr:competitor:169832', name: 'Mertens E / Schuurs D' }
      ]
    } }
  end
  let(:event) { create(:event, payload: payload) }

  it 'returns a list of competitors' do
    competitors = subject.competitors
    expect(competitors.count).to eq(2)
    expect(competitors[0].id).to eq('sr:competitor:405125')
    expect(competitors[1].id).to eq('sr:competitor:169832')
  end
end
