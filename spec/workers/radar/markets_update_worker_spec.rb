# frozen_string_literal: true

describe Radar::MarketsUpdateWorker do
  let(:response) do
    XmlParser.parse(file_fixture('radar_markets_descriptions.xml').read)
  end

  let(:variants_payload) do
    XmlParser.parse(file_fixture('radar_all_market_variants.xml').read)
  end

  let(:response_markets_count) do
    response.dig('market_descriptions', 'market').length
  end

  let(:client) { ::OddsFeed::Radar::Client.instance }
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
      attributes: nil,
      variants: false
    }.deep_stringify_keys!
  end

  let(:template_id) { '40' }
  let(:found_template) { MarketTemplate.find_by(external_id: template_id) }

  before do
    allow_any_instance_of(::OddsFeed::Radar::Client).to receive(:request)
    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:markets)
      .and_return(response)
    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:all_market_variants)
      .and_return(variants_payload)
    allow(subject).to receive(:client).and_return(client)
  end

  it 'requests market templates data from API' do
    subject.perform
    expect(client).to have_received(:markets)
  end

  it 'inserts new template in db if not exists' do
    subject.perform
    expect(MarketTemplate.count).to eq(response_markets_count)
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
    expect(MarketTemplate.count).to eq(response_markets_count - 1)
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
      attributes: nil,
      variants: false
    }.deep_stringify_keys!

    subject.perform

    expect(MarketTemplate.find_by(external_id: template_id).payload)
      .to eq(expected_payload)
  end

  context 'market template without outcomes' do
    let(:template_id) { '625' }
    let(:expected_payload) do
      {
        'specifiers' => {
          'specifier' => {
            'name' => 'mapnr',
            'type' => 'integer'
          }
        },
        'attributes' => nil,
        'products' => nil,
        'variants' => false
      }
    end

    before { subject.perform }

    it 'is saved' do
      expect(found_template.payload).to eq(expected_payload)
    end
  end

  context 'market template with many outcomes' do
    let(:template_id) { '282' }
    let(:expected_payload) do
      {
        'specifiers' => {
          'specifier' => {
            'name' => 'total',
            'type' => 'decimal'
          }
        },
        'attributes' => nil,
        'products' => nil,
        'variants' => false,
        'outcomes' => {
          'outcome' => [
            {
              'id' => '13',
              'name' => 'under {total}'
            },
            {
              'id' => '12',
              'name' => 'over {total}'
            }
          ]
        }
      }
    end

    before { subject.perform }

    it 'is saved' do
      expect(found_template.payload).to eq(expected_payload)
    end
  end

  context 'market template with one outcome' do
    let(:template_id) { '40' }
    let(:expected_payload) do
      {
        'specifiers' => nil,
        'attributes' => nil,
        'products' => nil,
        'variants' => false,
        'outcomes' => {
          'outcome' => [
            {
              'id' => '1716',
              'name' => 'no goal'
            }
          ]
        }
      }
    end

    before { subject.perform }

    it 'is saved' do
      expect(found_template.payload).to eq(expected_payload)
    end
  end

  context 'market template with variants without outcomes' do
    let(:template_id) { '672' }
    let(:expected_payload) do
      {
        'specifiers' => {
          'specifier' => [
            {
              'name' => 'inningnr',
              'type' => 'integer'
            },
            {
              'name' => 'variant',
              'type' => 'variable_text'
            }
          ]
        },
        'attributes' => nil,
        'products' => %w[5],
        'variants' => true
      }
    end

    before { subject.perform }

    it 'is saved' do
      expect(found_template.payload).to eq(expected_payload)
    end
  end

  context 'market template with variants' do
    let(:template_id) { '25' }
    let(:expected_payload) do
      {
        'specifiers' => {
          'specifier' => {
            'name' => 'variant',
            'type' => 'variable_text'
          }
        },
        'attributes' => nil,
        'products' => %w[1 3],
        'sr:point_range:6+' => {
          'outcomes' => {
            'outcome' => [
              { 'id' => 'sr:point_range:6+:1121', 'name' => '0-1' },
              { 'id' => 'sr:point_range:6+:1122', 'name' => '2-3' },
              { 'id' => 'sr:point_range:6+:1123', 'name' => '4-5' },
              { 'id' => 'sr:point_range:6+:1124', 'name' => '6+' }
            ]
          }
        },
        'sr:goal_range:7+' => {
          'outcomes' => {
            'outcome' => [
              { 'id' => 'sr:goal_range:7+:1342', 'name' => '0-1' },
              { 'id' => 'sr:goal_range:7+:1343', 'name' => '2-3' },
              { 'id' => 'sr:goal_range:7+:1344', 'name' => '4-6' },
              { 'id' => 'sr:goal_range:7+:1345', 'name' => '7+' }
            ]
          }
        },
        'sr:point_range:62+' => {
          'outcomes' => {
            'outcome' => [
              { 'id' => 'sr:point_range:62+:1125', 'name' => '0-46' },
              { 'id' => 'sr:point_range:62+:1126', 'name' => '47-49' },
              { 'id' => 'sr:point_range:62+:1127', 'name' => '50-52' },
              { 'id' => 'sr:point_range:62+:1128', 'name' => '53-55' },
              { 'id' => 'sr:point_range:62+:1129', 'name' => '56-58' },
              { 'id' => 'sr:point_range:62+:1130', 'name' => '59-61' },
              { 'id' => 'sr:point_range:62+:1131', 'name' => '62+' }
            ]
          }
        },
        'variants' => true
      }
    end

    before { subject.perform }

    it 'is saved' do
      expect(found_template.payload).to eq(expected_payload)
    end
  end

  context 'CreateOrUpdate service' do
    let(:variant_outcomes_map) do
      variants_payload
        .dig('variant_descriptions', 'variant')
        .map { |variant| map_variant(variant) }
        .to_h
    end

    def map_variant(variant)
      outcomes = Array.wrap(variant.dig('outcomes', 'outcome'))

      [variant['id'], { 'outcomes' => { 'outcome' => outcomes } }]
    end

    before do
      allow(OddsFeed::Radar::MarketTemplates::CreateOrUpdate)
        .to receive(:call)
        .and_call_original

      subject.perform
    end

    it 'every market data is processed using it' do
      response.dig('market_descriptions', 'market').each do |market_data|
        expect(OddsFeed::Radar::MarketTemplates::CreateOrUpdate)
          .to have_received(:call)
          .with(
            market_data: market_data,
            variant_outcomes_map: variant_outcomes_map
          )
      end
    end
  end
end
