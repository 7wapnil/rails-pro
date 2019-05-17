# frozen_string_literal: true

describe OddsFeed::Radar::MarketTemplates::CreateOrUpdate do
  subject { described_class.call(params) }

  let(:variant_outcomes_map) do
    {
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
      }
    }
  end

  let(:market_data) do
    XmlParser.parse(
      file_fixture('market_templates/market_data_with_many_variants.xml').read
    )['market']
  end

  let(:params) do
    {
      market_data: market_data,
      variant_outcomes_map: variant_outcomes_map
    }
  end

  it 'creates MarketTemplate' do
    expect { subject }.to change(MarketTemplate, :count).by(1)
  end

  context 'market template with variants' do
    let(:payload) do
      {
        'specifiers' => market_data['specifiers'],
        'attributes' => nil,
        'products' => %w[1 3],
        'variants' => true
      }.merge(variant_outcomes_map)
    end

    it 'assigns valid attributes' do
      expect(subject).to have_attributes(
        name: market_data['name'],
        groups: market_data['groups'],
        payload: payload
      )
    end

    context 'with created market template before' do
      before { create(:market_template, external_id: market_data['id']) }

      it 'overwrites all attributes' do
        expect(subject).to have_attributes(
          name: market_data['name'],
          groups: market_data['groups'],
          payload: payload
        )
      end
    end
  end

  context 'market template with variants without outcomes' do
    let(:market_data) do
      XmlParser.parse(
        file_fixture(
          'market_templates/market_data_with_variant_without_outcomes.xml'
        ).read
      )['market']
    end

    let(:payload) do
      {
        'specifiers' => market_data['specifiers'],
        'attributes' => nil,
        'products' => %w[5],
        'variants' => true
      }
    end

    it 'assigns valid attributes' do
      expect(subject).to have_attributes(
        name: market_data['name'],
        groups: market_data['groups'],
        payload: payload
      )
    end
  end

  context 'market template with one outcome' do
    let(:market_data) do
      XmlParser.parse(
        file_fixture(
          'market_templates/market_data_with_one_outcome.xml'
        ).read
      )['market']
    end

    let(:payload) do
      {
        'specifiers' => nil,
        'attributes' => nil,
        'products' => nil,
        'variants' => false,
        'outcomes' => {
          'outcome' => [{
            'id' => '1716',
            'name' => 'no goal'
          }]
        }
      }
    end

    it 'assigns valid attributes' do
      expect(subject).to have_attributes(
        name: market_data['name'],
        groups: market_data['groups'],
        payload: payload
      )
    end
  end

  context 'market template with many outcomes' do
    let(:market_data) do
      XmlParser.parse(
        file_fixture(
          'market_templates/market_data_with_many_outcomes.xml'
        ).read
      )['market']
    end

    let(:payload) do
      {
        'specifiers' => market_data['specifiers'],
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

    it 'assigns valid attributes' do
      expect(subject).to have_attributes(
        name: market_data['name'],
        groups: market_data['groups'],
        payload: payload
      )
    end
  end

  context 'market template without outcomes' do
    let(:market_data) do
      XmlParser.parse(
        file_fixture(
          'market_templates/market_data_without_outcomes.xml'
        ).read
      )['market']
    end

    let(:payload) do
      {
        'specifiers' => market_data['specifiers'],
        'attributes' => nil,
        'products' => nil,
        'variants' => false
      }
    end

    it 'assigns valid attributes' do
      expect(subject).to have_attributes(
        name: market_data['name'],
        groups: market_data['groups'],
        payload: payload
      )
    end
  end
end
