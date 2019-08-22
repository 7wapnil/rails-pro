# frozen_string_literal: true

require 'tempfile'

module Reports
  class BaseReport < ApplicationService
    def call
      send_report!
    end

    protected

    def subject_fields(_subject)
      error_msg = "#{__method__} needs to be implemented in #{self.class}"
      raise NotImplementedError, error_msg
    end

    def records_iterator
      error_msg = "#{__method__} needs to be implemented in #{self.class}"
      raise NotImplementedError, error_msg
    end

    def report_name
      "#{ENV['BRAND_NAME']}_#{self.class::REPORT_TYPE}_#{report_date}.csv"
    end

    private

    def send_report!
      temp_file = Tempfile.new
      temp_file.write(generated_report)
      temp_file.close

      Reports::FtpClient.new.connection do |ftp|
        ftp.putbinaryfile(temp_file, report_name)
      end

      temp_file.unlink
    end

    def generated_report
      CSV.generate(headers: true) do |csv|
        csv << self.class::HEADERS

        records_iterator do |subject|
          csv << subject_fields(subject)
        end
      end
    end

    def report_date
      Date.current.yesterday.strftime('%Y%m%d')
    end
  end
end
