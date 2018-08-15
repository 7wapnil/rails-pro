describe MarketsUpdateWorker do
  let(:response) do
    XmlParser.parse(file_fixture('radar_markets_descriptions.xml').read)
  end
  let(:client) do
    client = OddsFeed::Radar::Client.new
    allow(client).to receive(:request)
    allow(client).to receive(:markets).and_return(response)
    client
  end
  subject do
    subject = MarketsUpdateWorker.new
    allow(subject).to receive(:client).and_return(client)
    subject
  end

  it 'requests market templates data from API' do
    subject.perform
    expect(client).to have_received(:markets)
  end

  it 'inserts new template in db if not exists' do
    subject.perform
    expect(MarketTemplate.count).to eq(5)
  end

  it 'updates template in db if exists' do
    template_id = '701'
    create(:market_template, external_id: template_id,
                             name: 'Old template name',
                             groups: '')

    expected_payload = {
      outcomes: {
        outcome: [
          { 'id': '74', 'name': 'yes' },
          { 'id': '76', 'name': 'no' }
        ]
      },
      specifiers: {
        specifier: [
          { 'name': 'milestone', 'type': 'integer' },
          { 'name': 'maxovers', 'type': 'integer' }
        ]
      },
      attributes: nil
    }.deep_stringify_keys!

    subject.perform
    updated_template = MarketTemplate.find_by(external_id: template_id)
    expect(updated_template).to be_a(MarketTemplate)
    expect(updated_template.name).to eq('Any player to score {milestone}')
    expect(updated_template.groups).to eq('all')
    expect(updated_template.payload).to eq(expected_payload)
  end

  it 'skips creation on invalid data without breaking execution' do
    response['market_descriptions']['market'][0]['name'] = ''
    subject.perform
    expect(MarketTemplate.count).to eq(4)
  end
end
