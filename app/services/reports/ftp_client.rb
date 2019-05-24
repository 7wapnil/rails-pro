# frozen_string_literal: true

require 'net/ftp'

module Reports
  class FtpClient
    def connection
      Net::FTP.open(ENV['EVERYMATRIX_HOST']) do |ftp|
        ftp.login(ENV['EVERYMATRIX_USERNAME'], ENV['EVERYMATRIX_PASSWORD'])

        yield ftp
      end
    end
  end
end
