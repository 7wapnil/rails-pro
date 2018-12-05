module CustomersHelper
  def attachment_for(customer, kind)
    customer
      .verification_documents
      .where(kind: kind)
      .order(created_at: :desc)
      .first
  end

  def restricted_dob
    l(Date.current - 18.years, format: :date_picker)
  end

  def reset_password_link_data(customer)
    { data: { endpoint: reset_password_to_default_customer_path(customer),
              confirmation: t('messages.reset_password_confirmation',
                              customer_name: customer.full_name),
              success_message: t('messages.reset_password_success'),
              error_message: t('messages.reset_password_error') } }
  end
end
