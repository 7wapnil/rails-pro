describe OddsFeed::Radar::EventStatusService do
  subject(:service) { described_class.new }

  let(:match_status) do
    OddsFeed::Radar::MatchStatusMappingService.new
  end

  describe '.call' do
    context 'when not started event message' do
      let(:payload_not_started) do
        XmlParser.parse(
          file_fixture('event_status_not_started_message.xml').read
        )['odds_change']['sport_event_status']
      end
      let(:result_not_started) { service.call(payload_not_started) }

      it 'returns correct status' do
        expect(result_not_started[:status_code]).to eq(
          payload_not_started['match_status']
        )
        expect(result_not_started[:status]).to eq(
          match_status.call(
            payload_not_started['match_status'].to_i
          )
        )
      end

      it 'doesn\'t returns score' do
        expect(result_not_started[:score]).to be_nil
      end

      it 'doesn\'t returns time' do
        expect(result_not_started[:time]).to be_nil
      end

      it 'returns empty period scores' do
        expect(result_not_started[:period_scores]).to be_empty
      end

      it 'returns falsey finished value' do
        expect(result_not_started[:finished]).to be_falsey
      end
    end

    context 'when in progress event message with one period' do
      let(:payload_in_progress) do
        XmlParser.parse(
          file_fixture('event_status_in_progress_message.xml').read
        )['odds_change']['sport_event_status']
      end
      let(:result_in_progress) { service.call(payload_in_progress) }

      it 'returns correct status' do
        expect(result_in_progress[:status_code]).to eq(
          payload_in_progress['match_status']
        )
        expect(result_in_progress[:status]).to eq(
          match_status.call(
            payload_in_progress['match_status'].to_i
          )
        )
      end

      it 'returns correct score' do
        expect(result_in_progress[:score]).to eq(
          # rubocop:disable Metrics/LineLength
          "#{payload_in_progress['home_score']}:#{payload_in_progress['away_score']}"
          # rubocop:enable Metrics/LineLength
        )
      end

      it 'returns correct time' do
        expect(result_in_progress[:time]).to eq(
          payload_in_progress['clock']['match_time']
        )
      end

      it 'returns period scores' do
        expect(result_in_progress[:period_scores]).to_not be_empty
        expect(result_in_progress[:period_scores].count).to eq(1)
      end

      it 'returns falsey finished value' do
        expect(result_in_progress[:finished]).to be_falsey
      end
    end

    context 'when finished event message with multiple periods' do
      let(:payload_ended) do
        XmlParser.parse(
          file_fixture('event_status_ended_message.xml').read
        )['odds_change']['sport_event_status']
      end
      let(:result_ended) { service.call(payload_ended) }

      it 'returns correct status' do
        expect(result_ended[:status_code]).to eq(payload_ended['match_status'])
        expect(result_ended[:status]).to eq(
          match_status.call(
            payload_ended['match_status'].to_i
          )
        )
      end

      it 'returns correct score' do
        expect(result_ended[:score]).to eq(
          "#{payload_ended['home_score']}:#{payload_ended['away_score']}"
        )
      end

      it 'doesn\'t returns time' do
        expect(result_ended[:time]).to be_nil
      end

      it 'returns period scores' do
        expect(result_ended[:period_scores]).to_not be_empty
        expect(result_ended[:period_scores].count).to eq(
          payload_ended['period_scores']['period_score'].size
        )
      end

      it 'returns truthy finished value' do
        expect(result_ended[:finished]).to be_truthy
      end
    end
  end
end
