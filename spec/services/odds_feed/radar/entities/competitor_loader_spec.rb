# frozen_string_literal: true

describe OddsFeed::Radar::Entities::CompetitorLoader do
  subject { described_class.new(external_id: external_id) }

  let(:payload) do
    XmlParser.parse(file_fixture('radar_competitor_profile.xml').read)
  end
  let(:competitor_profile_from_xml) { payload['competitor_profile'] }
  let(:competitor_from_xml) { competitor_profile_from_xml['competitor'] }
  let(:external_id) { competitor_from_xml['id'] }

  let(:cache_settings) do
    {
      cache: { expires_in: OddsFeed::Radar::Client::DEFAULT_CACHE_TERM }
    }
  end

  let(:name) do
    competitor_from_xml['name']
      .split(described_class::NAME_SEPARATOR)
      .reverse
      .join(' ')
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:competitor_profile)
      .with(external_id, cache_settings)
      .and_return(payload)

    allow(competitor_profile_from_xml)
      .to receive(:dig)
      .and_call_original
  end

  context 'with cached competitor' do
    before { allow(Rails.cache).to receive(:read).and_return(name) }

    it 'takes competitor from cache' do
      expect(Rails.cache).to receive(:read)
      subject.call
    end

    it 'returns competitor name' do
      expect(subject.call).to eq(name)
    end

    it 'does not perform API call' do
      expect(subject).not_to receive(:radar_entity_name)
      subject.call
    end

    it 'does not try to read and cache players from payload' do
      expect(competitor_profile_from_xml)
        .not_to receive(:dig)
        .with('players', 'player')
      subject.call
    end
  end

  context 'with new competitor from Radar API' do
    let(:subject_with_name) { described_class.new(external_id: external_id) }

    before { allow(Rails.cache).to receive(:write) }

    it 'caches competitor' do
      expect(Rails.cache).to receive(:write)
      subject_with_name.call
    end

    it 'returns competitor name' do
      expect(subject_with_name.call).to eq(name)
    end

    it 'performs API call only once' do
      expect(subject_with_name)
        .to receive(:radar_entity_name)
        .once
        .and_call_original
      subject_with_name.call
    end

    context 'with team sport competitor' do
      let(:payload) do
        XmlParser
          .parse(file_fixture('radar_team_sport_competitor_profile.xml').read)
      end

      it 'tries to read and cache players from payload' do
        expect(competitor_profile_from_xml)
          .to receive(:dig)
          .with('players', 'player')
        subject.call
      end

      it_behaves_like 'service caches competitors and players' do
        let(:competitor_payload) { payload }
        let(:competitor_id) { external_id }
        let(:competitor_name) { name }
        let(:service_call) { subject_with_name.call }
      end
    end
  end
end
