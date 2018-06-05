class EntryRequestPayloadValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? || value.valid?

    record.errors[attribute] << value.errors.full_messages
  end
end
