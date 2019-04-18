module CustomersHelper
  def attachment_for(customer, kind)
    customer
      .verification_documents
      .where(kind: kind)
      .order(created_at: :desc)
      .first
  end

  def allowed_account_kind_options(customer)
    allowed_kinds = if customer.regular?
                      Customer.account_kinds.keys
                    else
                      [customer.account_kind]
                    end

    options_for_select(allowed_kinds, customer.account_kind)
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

  def balance_kinds_options
    Balance.kinds.map { |k, _| [t("kinds.#{k}"), k] }
  end

  def entry_kinds_options
    Entry.kinds.map { |k, _| [t("kinds.#{k}"), k] }
  end

  def customer_wallets_options(customer)
    customer.wallets.includes(:currency).map do |wallet|
      [
        "#{wallet.currency_code} : #{wallet.amount}",
        wallet.id
      ]
    end
  end

  def entry_kind_link_name(balance_entry)
    "#{t('kinds.' + balance_entry.entry.kind)} ##{balance_entry.entry.id}"
  end

  def balance_change_badge_class(balance_entry)
    "badge badge-#{balance_entry.amount.positive? ? 'success' : 'danger'}"
  end
end
