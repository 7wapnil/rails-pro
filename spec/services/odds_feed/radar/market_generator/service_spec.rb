# frozen_string_literal: true

describe OddsFeed::Radar::MarketGenerator::Service do
  let(:markets_data) do
    XmlParser
      .parse(file_fixture('odds_change_message.xml').read)
      .dig('odds_change', 'odds', 'market')
  end

  let(:markets_data_count) { markets_data.count }

  let(:producer_id_in_file) { 2 }
  let(:event_external_id_in_file) { 'sr:match:1234' }

  let!(:producer) { create(:producer, id: producer_id_in_file) }
  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }

  let!(:event) do
    create(:event, external_id: event_external_id_in_file, producer: producer)
  end

  let(:preloaded_market_template_ids) do
    markets_data.map { |data| data['id'] }
  end

  let!(:preload_market_templates) do
    preloaded_market_template_ids.map do |id|
      create(:market_template, :with_outcome_data, external_id: id)
    end
  end

  before do
    allow_any_instance_of(::OddsFeed::Radar::Client)
      .to receive(:request)
  end

  describe 'market attributes' do
    subject do
      described_class.new(
        event: event,
        markets_data: markets_data,
        message_producer_id: 1
      )
    end

    let(:template) { MarketTemplate.find_by!(external_id: '188') }

    it 'assigns market template' do
      subject.call

      expect(Market.find_by!(external_id: 'sr:match:1234:188').template)
        .to eq(template)
    end
  end

  describe '#call' do
    subject do
      described_class.call(
        event: event,
        markets_data: markets_data,
        message_producer_id: 1
      )
    end

    let(:web_socket) { double }
    let(:odds)       { build_stubbed_list(:odd, 5) }
    let(:markets)    { build_stubbed_list(:market, markets_data.count) }

    let(:market_data_id) { 47 }
    let(:market_data_based_market_external_id) { 'sr:match:1234:47/score=41.5' }

    let(:source_template) do
      MarketTemplate.find_by(external_id: market_data_id)
    end
    let(:market_created_from_template) do
      Market.find_by(external_id: market_data_based_market_external_id)
    end

    before do
      allow(WebSocket::Client).to receive(:instance).and_return(web_socket)
      allow(web_socket).to receive(:trigger_event_update)
      allow(web_socket).to receive(:trigger_provider_update)

      allow(OddsFeed::Radar::Entities::PlayerLoader)
        .to receive(:call) { Faker::Name.name }
    end

    shared_context 'mute real import' do
      before do
        allow(OddsFeed::Radar::MarketGenerator::OddsGenerator)
          .to receive(:call)
          .and_return(odds)

        allow(Market).to receive(:import)
        allow(Odd).to    receive(:import)
      end
    end

    context 'build markets' do
      include_context 'mute real import'

      before do
        allow_any_instance_of(OddsFeed::Radar::MarketGenerator::MarketData)
          .to receive(:name)
        allow(Market).to receive(:new).and_return(*markets)
      end

      context 'proceed only valid markets' do
        let(:valid_markets_count) { rand(markets_data.count) }
        let(:valid_markets) { build_stubbed_list(:market, valid_markets_count) }
        let(:invalid_markets) do
          build_stubbed_list(
            :market,
            markets_data.count - valid_markets_count,
            name: nil
          )
        end
        let(:markets) { [*valid_markets, *invalid_markets] }

        it do
          expect(OddsFeed::Radar::MarketGenerator::OddsGenerator)
            .to receive(:call)
            .exactly(valid_markets_count)
            .times
          subject
        end

        it { expect { subject }.not_to raise_error }
      end
    end

    context 'import' do
      include_context 'mute real import'

      before do
        allow(Market).to receive(:new).and_return(*markets)

        subject
      end

      it 'imports markets' do
        expect(Market)
          .to have_received(:import)
          .with(markets, hash_including)
          .once
      end

      it 'imports odds' do
        expect(Odd)
          .to have_received(:import)
          .with(array_including(odds), hash_including)
          .once
      end
    end

    context 'with market templates cache' do
      subject do
        described_class.call(
          event: event,
          markets_data: markets_data,
          message_producer_id: 1
        )
      end

      before do
        allow(MarketTemplate).to receive('find_by!').and_call_original
        subject
      end

      let(:mutated_name) { Faker::Lorem.word }
      let(:mutated_template) do
        source_template
          .clone
          .tap { |template| template.update(name: mutated_name) }
      end

      it 'creates correct number of markets' do
        expect(Market.count).to eq markets_data_count
      end
    end
  end
end
