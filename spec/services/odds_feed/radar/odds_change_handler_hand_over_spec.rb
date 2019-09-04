# frozen_string_literal: true

# rubocop:disable RSpec/ExpectInHook
describe OddsFeed::Radar::OddsChangeHandler do
  subject { described_class.new(payload) }

  let(:external_id) { 'sr:match:1234' }
  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:event) do
    create(
      :event,
      external_id: external_id,
      remote_updated_at: nil,
      producer_id: event_producer_id
    )
  end
  let(:event_producer_id) { prematch_producer.id }
  let(:payload) { XmlParser.parse(payload_xml) }
  let(:template) { create(:market_template) }
  let(:specifiers) { 'hcp=1:0' }
  let(:market_external_id) do
    "#{external_id}:#{template.external_id}/#{specifiers}"
  end
  let(:market) do
    create(
      :market,
      event: event,
      external_id: market_external_id,
      template: template,
      template_specifiers: specifiers
    )
  end
  let(:payload_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <odds_change product="#{message_producer_id}" event_id="#{external_id}" timestamp="#{Time.now.to_i}" request_id="1564727279">
        <odds>
          <market status="-2" id="#{template.external_id}" specifiers="#{specifiers}"/>
        </odds>
      </odds_change>
    XML
  end

  before do
    allow(::EventsManager::EventLoader).to receive(:call).and_return(event)
    allow(WebSocket::Client.instance).to receive(:trigger_event_update)
    allow(EventsManager::Entities::Event)
      .to receive(:type_match?)
      .and_return(true)
  end

  # Hand over
  describe 'new markets created inactive' do
    context 'match producer: prematch, message producer: prematch' do
      let(:message_producer_id) { prematch_producer.id }

      it 'market status is inactive' do
        subject.handle

        the_market = Market.find_by(external_id: market_external_id)

        expect(the_market.status).to eq(Market::INACTIVE)
      end
    end
  end

  describe 'hand over suspending prematch markets' do
    context 'match producer: prematch, message producer: prematch' do
      let(:message_producer_id) { prematch_producer.id }
      let(:event_producer_id) { liveodds_producer.id }

      before do
        market.update_column(:producer_id, prematch_producer.id)
      end

      it 'market status is suspended' do
        subject.handle

        the_market = Market.find_by(external_id: market_external_id)

        expect(the_market.status).to eq(Market::SUSPENDED)
      end
    end
  end

  describe 'hand over ignoring market deactivation' do
    before do
      expect_any_instance_of(JobLogger).to(
        receive(:log_job_message).with(
          :warn,
          message:
            OddsFeed::Radar::MarketGenerator::Service::SKIP_MARKET_MESSAGE,
          event_id: external_id,
          event_producer_id: event_producer_id,
          message_producer_id: message_producer_id,
          market_data: {
            'id' => template.external_id,
            'specifiers' => market.template_specifiers,
            'status' => '-2'
          }
        ).once
      )
    end

    context 'match producer: prematch, message producer: live' do
      let(:message_producer_id) { liveodds_producer.id }

      it 'logs warning, market status active' do
        subject.handle

        expect(market.reload.status).to eq(Market::ACTIVE)
      end
    end

    context 'match producer: live, message producer: live' do
      let(:message_producer_id) { liveodds_producer.id }
      let(:event_producer_id) { liveodds_producer.id }

      before { event.update_attribute(:producer_id, event_producer_id) }

      it 'logs warning, market status active' do
        subject.handle

        expect(market.reload.status).to eq(Market::ACTIVE)
      end
    end
  end
end
# rubocop:enable RSpec/ExpectInHook
