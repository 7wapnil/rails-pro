require 'faker'
require 'factory_bot_rails'

puts 'Creating Customers ...'

10.times do
  FactoryBot.create(:customer)
end

Customer.all.each do |customer|
  FactoryBot.create(:address, :with_state, customer: customer)
end
