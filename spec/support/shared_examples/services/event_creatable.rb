# frozen_string_literal: true

shared_examples 'service caches competitors and players' do
  let(:player_names) do
    competitor_payload
      .dig('competitor_profile', 'players', 'player')
      .map { |player| player.values_at('id', 'full_name') }
      .to_h
      .transform_keys { |key| "entity-names:#{key}" }
  end

  before do
    allow_any_instance_of(OddsFeed::Radar::Client)
      .to receive(:competitor_profile)
      .with(competitor_id, any_args)
      .and_return(competitor_payload)

    allow(Rails.cache).to receive(:write)
    allow(Rails.cache).to receive(:write_multi)
    allow(OddsFeed::Radar::EventBasedCache::Writer)
      .to receive(:call)
      .and_call_original

    service_call
  end

  it 'caches competitor' do
    expect(Rails.cache)
      .to have_received(:write)
      .with(
        "entity-names:#{competitor_id}",
        competitor_name,
        cache: {
          expires_in: OddsFeed::Radar::Entities::BaseLoader::CACHE_TERM
        }
      )
  end

  it 'caches players' do
    expect(Rails.cache)
      .to have_received(:write_multi)
      .with(
        player_names,
        cache: {
          expires_in: OddsFeed::Radar::Entities::BaseLoader::CACHE_TERM
        }
      )
  end
end
