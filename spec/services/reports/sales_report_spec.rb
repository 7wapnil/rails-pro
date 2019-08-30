# frozen_string_literal: true

require 'net/ftp'

describe Reports::SalesReport do
  subject { described_class }

  let(:connection_double) { double }

  before do
    allow(connection_double).to receive(:putbinaryfile)
    allow(connection_double).to receive(:login)
    allow(::Net::FTP).to receive(:open).and_yield(connection_double)
  end

  describe '#call' do
    it 'sends report via ftp' do
      expect_any_instance_of(::Reports::FtpClient)
        .to receive(:connection)

      subject.call
    end

    it 'creates report' do
      expect_any_instance_of(Tempfile)
        .to receive(:write)

      subject.call
    end
  end

  describe '#records_iterator' do
    it 'calls Sales Report Query' do
      expect_any_instance_of(::Reports::Queries::SalesReportQuery)
        .to receive(:batch_loader)

      subject.call
    end
  end
end
