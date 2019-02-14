# frozen_string_literal: true

shared_examples 'takes only active and visible events' do
  let(:valid_events) { [] }

  context 'inactive events' do
    before do
      valid_events.each { |event| event.update(active: false) }
    end

    it 'are ignored' do
      expect(result_event_ids).not_to include(*valid_events.map(&:id))
    end
  end

  context 'invisible events' do
    before { valid_events.each(&:invisible!) }

    it 'are ignored' do
      expect(result_event_ids).not_to include(*valid_events.map(&:id))
    end
  end
end
