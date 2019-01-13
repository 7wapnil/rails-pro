module CreateRecordMatcher
  class CreateRecordMatcher
    def initialize(record_class)
      @record_class = record_class
    end

    def matches?(_subject = nil)
      records_exists? && matches_attributes? && matches_count?
    end

    def supports_block_expectations?
      true
    end

    def count(count)
      @count = count

      self
    end

    def with_attributes(attrs)
      @attributes = attrs

      self
    end

    def records_exists?
      record_class.exists?
    end

    def matches_count?
      return true unless @count

      @count == records_source.count
    end

    def matches_attributes?
      return true if @attributes.blank?

      record_class.where(@attributes).exists?
    end

    def failure_message
      msg = 'Expected to have created '
      msg << "#{@count} '#{record_class.name}' #{'record'.pluralize(@count)}"
      msg << " wit attributes: #{@attributes}" if @attributes.present?
      msg
    end

    def failure_message_when_negated
      msg = 'Expected to have not created '
      msg << "#{@count} '#{record_class.name}' #{'record'.pluralize(@count)}"
      msg << " wit attributes: #{@attributes}" if @attributes.present?
      msg
    end

    private

    attr_reader :record_class

    def records_source
      @attributes.present? ? record_class.where(@attributes) : record_class
    end
  end

  # Helper methods declaration
  def have_created_record(record_class)
    CreateRecordMatcher.new(record_class)
  end

  def have_balance_entry_request
    CreateRecordMatcher.new(BalanceEntryRequest)
  end

  def have_balance_entry
    CreateRecordMatcher.new(BalanceEntry)
  end
end

RSpec.configure do |config|
  config.include CreateRecordMatcher
end
