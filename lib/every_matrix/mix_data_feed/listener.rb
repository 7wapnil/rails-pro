# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class Listener
      FEED_URL = ENV['EVERY_MATRIX_FEED_URL']
      FEED_TYPES = [
        GAME = 'game',
        TABLE = 'table',
        VENDOR = 'vendor',
        CONTENT_PROVIDER = 'contentprovider',
        DATA_SOURCE = 'datasource'
        # RECENT_WINNER = 'recentwinner'
      ].freeze

      ROW_SEPARATOR = "\r\n"
      WHITESPACE_REGEX = /(\A\r\n)|((\r\n|\r)\z)/
      COMPLETED_ROW_WHITESPACE_REGEX = /\A\n/
      TYPE_REGEX = /"type"\s*:\s*".*",/

      def initialize(connection_state: nil)
        @connection_state = connection_state || EveryMatrix::Connection.instance
        @buffer = ''
      end

      def listen
        request = build_request
        request.on_headers { |*| log_connection_established }
        request.on_body { |chunk| on_body(chunk) }
        request.on_complete { |response| on_complete(response) }

        request.run
      end

      private

      attr_reader :connection_state, :buffer

      def build_request
        ::Typhoeus::Request.new(
          "#{FEED_URL}/#{ENV['EVERY_MATRIX_OPERATOR_KEY']}",
          method: :get,
          params: { types: FEED_TYPES.join(',') },
          headers: request_headers
        )
      end

      def request_headers
        {
          Accept: 'application/json-stream',
          Connection: 'Keep-Alive',
          'Cache-Control': 'no-store,no-cache',
          Pragma: 'no-cache'
        }
      end

      def log_connection_established
        Rails.logger.info('Connection established successfully')
      end

      def on_body(raw_chunk)
        return health_check! if raw_chunk.blank?

        "#{buffer}#{strip_chunk(raw_chunk)}"
          .split(ROW_SEPARATOR)
          .tap { |batch| @buffer = !holistic_row?(batch.last) ? batch.pop : '' }
          .each { |row| process_row(row) }
      end

      def health_check!
        connection_state.with_lock { connection_state.touch }
      end

      def strip_chunk(raw_chunk)
        chunk = raw_chunk.gsub(WHITESPACE_REGEX, '')
        chunk = chunk.gsub(COMPLETED_ROW_WHITESPACE_REGEX, '') if buffer.blank?

        chunk.encode(
          'UTF-8', 'binary', invalid: :replace, undef: :replace, replace: ''
        ).force_encoding('UTF-8')
      end

      def holistic_row?(row)
        return false unless row.start_with?('{') && row.end_with?('}')

        JSON.parse(row).key?('domainID')
      rescue JSON::ParserError
        false
      end

      def on_complete(response)
        if response.success? then 'Response received'
        elsif response.timed_out? then 'Connection timed out'
        elsif response.code.zero? then response.return_message
        else "Failure. Body: #{response.body}, Code: #{response.code}"
        end

        raise EveryMatrix::ConnectionClosedError, response.return_message
      end

      def process_row(raw_data)
        feed_type = raw_data.match(TYPE_REGEX).to_s
                            .delete('"')
                            .split(',').first
                            .split(':').last

        processing_worker_class(feed_type).perform_async(raw_data)
      end

      def processing_worker_class(feed_type)
        case feed_type
        when GAME then GameWorker
        when TABLE then TableWorker
        when VENDOR then VendorWorker
        when CONTENT_PROVIDER then ContentProviderWorker
        when DATA_SOURCE then DataSourceWorker
        # when RECENT_WINNER then RecentWinnerWorker
        else raise "Wrong feed type: #{feed_type}"
        end
      end
    end
  end
end
