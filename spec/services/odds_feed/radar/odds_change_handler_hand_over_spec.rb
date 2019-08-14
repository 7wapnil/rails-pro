# frozen_string_literal: true

# rubocop:disable RSpec/ExpectInHook
describe OddsFeed::Radar::OddsChangeHandler do
  subject { described_class.new(payload) }

  let(:external_id) { 'sr:match:1234' }
  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:event) do
    create(:event,
           external_id: external_id,
           remote_updated_at: nil,
           producer: prematch_producer)
  end
  let(:payload) { XmlParser.parse(payload_xml) }
  let(:template) { create(:market_template) }
  let(:specifiers) { 'hcp=1:0' }
  let(:market) do
    create(
      :market,
      event: event,
      external_id: "#{external_id}:#{template.external_id}/#{specifiers}",
      template: template,
      template_specifiers: specifiers
    )
  end
  let(:payload_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <odds_change product="#{message_producer_id}" event_id="#{external_id}" timestamp="#{Time.now.to_i}" request_id="1564727279">
        <odds>
          <market status="-2" id="#{template.external_id}" specifiers="#{market.template_specifiers}"/>
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
  describe 'hand over deactivating markets' do
    context 'match producer: prematch, message producer: prematch' do
      let(:message_producer_id) { ::Radar::Producer::PREMATCH_PROVIDER_ID }

      it 'changes the market status to inactive' do
        subject.handle

        expect(market.reload.status).to eq(Market::INACTIVE)
      end
    end
  end

  describe 'hand over ignoring market deactivation' do
    before do
      expect_any_instance_of(JobLogger).to(
        receive(:log_job_message).with(
          :warn,
          message: 'Got -2 market status from of for non-prematch producer.',
          market_data: {
            'id' => template.external_id,
            'specifiers' => market.template_specifiers,
            'status' => '-2'
          }
        ).once
      )
    end

    context 'match producer: prematch, message producer: live' do
      let(:message_producer_id) { ::Radar::Producer::LIVE_PROVIDER_ID }

      it 'logs warning, market status active' do
        subject.handle

        expect(market.reload.status).to eq(Market::ACTIVE)
      end
    end

    context 'match producer: live, message producer: prematch' do
      let(:message_producer_id) { ::Radar::Producer::PREMATCH_PROVIDER_ID }

      before do
        event.update_attribute(
          :producer_id,
          ::Radar::Producer::LIVE_PROVIDER_ID
        )
      end

      it 'logs warning, market status active' do
        subject.handle

        expect(market.reload.status).to eq(Market::ACTIVE)
      end
    end

    context 'match producer: live, message producer: live' do
      let(:message_producer_id) { ::Radar::Producer::LIVE_PROVIDER_ID }

      before do
        event.update_attribute(
          :producer_id,
          ::Radar::Producer::LIVE_PROVIDER_ID
        )
      end

      it 'logs warning, market status active' do
        subject.handle

        expect(market.reload.status).to eq(Market::ACTIVE)
      end
    end
  end
end
# rubocop:enable RSpec/ExpectInHook
