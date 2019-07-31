# frozen_string_literal: true

describe OddsFeed::Radar::ProducerUpdateService do
  subject { described_class.call(event: event, producer_id: new_producer_id) }

  let!(:liveodds_producer) { create(:liveodds_producer) }
  let!(:prematch_producer) { create(:prematch_producer) }
  let!(:event) { create(:event, producer_id: producer_id) }

  context 'from prematch to live' do
    let(:producer_id) { prematch_producer.id }
    let(:new_producer_id) { liveodds_producer.id }

    it 'changes event producer' do
      subject

      expect(event.producer_id).to eq(liveodds_producer.id)
    end
  end

  context 'from live to prematch' do
    let(:producer_id) { liveodds_producer.id }
    let(:new_producer_id) { prematch_producer.id }

    it 'changes event producer' do
      subject

      expect(event.producer_id).to eq(liveodds_producer.id)
    end
  end
end
