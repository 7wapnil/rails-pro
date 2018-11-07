class AgeValidator < ActiveModel::Validator
  ADULT_AGE = 18
  def validate(record)
    @record = record
    return store_error_message unless record.date_of_birth

    adult = (record.date_of_birth + ADULT_AGE.years) <= Time.zone.now
    store_error_message unless adult
  end

  private

  def store_error_message
    error_message = I18n.t('errors.messages.age_adult')
    @record.errors[:date_of_birth] << error_message
  end
end
