describe OddsFeed::Radar::OddsChangeHandler, :perf do
  let!(:base_payload) do
    XmlParser.parse(file_fixture('odds_change_message.xml').read)
  end

  let(:markets_count) { 500 }

  let(:preloaded_market_template_ids) do
    (1..markets_count).to_a
  end

  let!(:preload_market_templates) do
    templates = preloaded_market_template_ids.map do |id|
      build(:market_template, :with_outcome_data, external_id: id)
    end
    MarketTemplate.import(templates, validate: false)
  end

  let(:producer_id_in_file) { 2 }
  let(:event_external_id_in_file) { 'sr:match:1234' }

  let(:producer) { create(:producer, id: producer_id_in_file) }

  let!(:event) do
    create(:event, external_id: event_external_id_in_file, producer: producer)
  end

  let!(:custom_payload) do
    payload = XmlParser.parse(file_fixture('odds_change_message.xml').read)
    payload['odds_change']['odds']['market'] =
      preloaded_market_template_ids.map do |market_template_id|
        {
          id: market_template_id.to_s,
          specifiers: 'score=41.5',
          favorite: '1',
          status: '1',
          outcome: Array.new(3).each_with_index.map do |_, i|
            {
              id: i + 1,
              odds: 1.43,
              active: 1
            }.stringify_keys.transform_values(&:to_s)
          end
        }.stringify_keys
      end

    payload
  end

  let(:payload) { custom_payload }

  before do
    allow(WebSocket::Client.instance).to receive(:trigger_event_update)
    allow(WebSocket::Client.instance).to receive(:trigger_market_update)
    allow_any_instance_of(OddsFeed::Radar::Client).to receive(:player_profile)
  end

  context 'validate payload' do
    it 'has valid payload to test' do
      expect { payload }.not_to raise_error
    end
  end

  def execute_performance_test(experiments_count: 1)
    test_results = Array.new(experiments_count).map do
      result_time = nil
      GC.start
      ActiveRecord::Base.connection.query_cache.clear

      DatabaseCleaner.cleaning do
        result_time = Benchmark.realtime do
          yield
        end
      end

      result_time
    end
    test_results.instance_eval { reduce(:+) / size.to_f }
  end

  it 'runs faster with cached markets' do
    # Heat the DB
    execute_performance_test(experiments_count: 2) do
      described_class.new(payload).handle
    end

    experiments_count = 3

    time_with_optimization =
      execute_performance_test(experiments_count: experiments_count) do
        described_class.new(
          payload,
          configuration: { cached_market_templates: true }
        ).handle
      end

    time_without_optimization =
      execute_performance_test(experiments_count: experiments_count) do
        described_class.new(
          payload,
          configuration: { cached_market_templates: false }
        ).handle
      end

    results = {
      without_optimization: time_without_optimization.round(2).to_s,
      with_optimization: time_with_optimization.round(2).to_s,
      improvement_percentage:
        ((1 - time_with_optimization / time_without_optimization) * 100)
              .round(2).to_s
    }
    Rails.logger.info results.to_json

    expect(time_with_optimization.real < time_without_optimization.real)
      .to be_truthy
  end
end
