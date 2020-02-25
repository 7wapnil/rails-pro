namespace :data_adjustments do
  desc 'Removes customer\'s funds with a system error entry'
  task remove_customer_balance: :environment do
    DataAdjustments::RemoveCustomerBalance.call(ENV.fetch('CUSTOMER_ID'))
  end
end
