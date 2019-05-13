# frozen_string_literal: true

require 'net/ftp'

module Reports
  class FtpClient < ApplicationService
    # remove default params before commit
    def initialize(report_type: 'registration',
                   file_name: "registration_report_for_#{Time.now.strftime('%d.%m.%y')}.csv")
      @report_type = report_type
      @file_name = file_name
    end

    def call
      send_file
    end

    private

    attr_reader :report_type

    def send_file
      open_connection do |ftp|
        report_type_folder!(ftp)
        monthly_report_folder!(ftp)
      end
    end

    def open_connection
      Net::FTP.open(ENV['EVERYMATRIX_HOST']) do |ftp|
        ftp.login(ENV['EVERYMATRIX_USERNAME'], ENV['EVERYMATRIX_PASSWORD'])

        yield ftp
      end
    end

    def folder_exist?(ftp, name, path = '')
      ftp.list("/#{path}").any? { |dir| dir.match(/\s#{name}$/) }
    end

    def report_type_folder!(ftp)
      return if folder_exist?(ftp, report_type_folder_name)

      ftp.mkdir("/#{report_type_folder_name}")
    end

    def report_type_folder_name
      @report_type_folder_name ||= report_type.capitalize + '_Reports'
    end

    def monthly_report_folder!(ftp)
      return if monthly_report_folder_exist?(ftp)

      ftp.mkdir("/#{report_type_folder_name}/#{monthly_report_folder_name}")
    end

    def monthly_report_folder_name
      @monthly_report_folder_name ||= Time.now.strftime('%b_%Y')
    end

    def monthly_report_folder_exist?(ftp)
      folder_exist?(ftp, monthly_report_folder_name, report_type_folder_name)
    end
  end
end
