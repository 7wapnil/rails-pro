# frozen_string_literal: true

require 'net/ftp'

describe Reports::SalesReport do
  subject { described_class }

  let(:control_customers) { create_list(:customer, 3, b_tag: '123123') }
  let!(:test_customers) { create_list(:customer, 3) }
  let(:connection_double) { double }

  before do
    control_customers.each do |customer|
      wallet = create(:wallet, customer: customer,
                               currency: create(:currency, :primary))
      create(:entry, :bet, :recent,
             wallet: wallet,
             entry_request: nil,
             origin: create(:bet, customer: customer, status: :settled))
      create(:entry, :deposit, :recent,
             wallet: wallet,
             entry_request: nil,
             origin: create(:bet, customer: customer, status: :settled))
      create(:entry, :win, :recent,
             wallet: wallet,
             entry_request: nil,
             origin: create(:bet, customer: customer, status: :settled))
    end

    test_customers.each do |customer|
      wallet = create(:wallet, customer: customer,
                               currency: create(:currency, :primary))
      create(:entry, :bet, wallet: wallet, entry_request: nil)
      create(:entry, :deposit, wallet: wallet, entry_request: nil)
      create(:entry, :win, wallet: wallet, entry_request: nil)
    end

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

  describe '#subjects' do
    it 'returns correct list of customers' do
      expect(subject.new.send(:subjects).length)
        .to eq(control_customers.length)
    end
  end
end
