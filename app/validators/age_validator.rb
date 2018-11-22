class AgeValidator < ActiveModel::Validator
  ADULT_AGE = 18
  def validate(record)
    @record = record

    store_error_message if record.date_of_birth.blank? || young?(record)
  end

  private

  def young?(record)
    (record.date_of_birth.in_time_zone + ADULT_AGE.years) > Time.zone.now
  end

  def store_error_message
    error_message = I18n.t('errors.messages.age_adult')
    @record.errors[:date_of_birth] << error_message
  end
end
