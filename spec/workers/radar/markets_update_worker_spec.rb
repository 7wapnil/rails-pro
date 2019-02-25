describe Radar::MarketsUpdateWorker do
  let(:response) do
    XmlParser.parse(file_fixture('radar_markets_descriptions.xml').read)
  end
  let(:client) { OddsFeed::Radar::Client.new }
  let(:expected_payload) do
    {
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
      products: nil,
      attributes: nil
    }.deep_stringify_keys!
  end

  before do
    allow(client).to receive(:request)
    allow(client).to receive(:markets).and_return(response)
    allow(subject).to receive(:client).and_return(client)
  end

  it 'requests market templates data from API' do
    subject.perform
    expect(client).to have_received(:markets)
  end

  it 'inserts new template in db if not exists' do
    subject.perform
    expect(MarketTemplate.count).to eq(6)
  end

  it 'updates template in db if exists' do
    template_id = '701'
    create(:market_template, external_id: template_id,
                             name: 'Old template name',
                             groups: '')

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
    expect(MarketTemplate.count).to eq(5)
  end

  it 'saves markets with single outcome as array' do
    template_id = '40'
    expected_payload = {
      outcomes: {
        outcome: [
          { 'id': '1716', 'name': 'no goal' }
        ]
      },
      specifiers: nil,
      products: nil,
      attributes: nil
    }.deep_stringify_keys!

    subject.perform

    expect(MarketTemplate.find_by(external_id: template_id).payload)
      .to eq(expected_payload)
  end
end
