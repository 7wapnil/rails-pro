bets_count = Bet.count

bets_to_create_count = 250 - bets_count

puts 'Creating Bets ...'

return unless bets_to_create_count.positive?

bets = []

bets_to_create_count.times do
  customer = Customer.order(Arel.sql('RANDOM()')).select(:id).first

  currency = Currency.order(Arel.sql('RANDOM()')).select(:id).first

  odd = Odd.order(Arel.sql('RANDOM()')).select(:id, :value).first

  bet = Bet.new(
    customer: customer,
    currency: currency,
    odd: odd,
    amount: Faker::Number.between(1, 1000),
    odd_value: odd.value,
    message: 'I am rich text message'
  )

  bets << bet
end

Bet.import bets, on_duplicate_key_ignore: true
