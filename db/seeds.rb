Credit.delete_all
User.delete_all

User.import(30_000.times.map { User.random })
credits_generator = RandomCreditsGenerator.new(user_ids: User.pluck(:id))

import_credits = -> {
  unless credits.empty?
    Credit.connection.execute("INSERT INTO credits(#{cols}) VALUES #{credits}")
  end

  credits = ''
}

total_credits = 1_000_000
batch_size = 20_000
cols = ''
credits = ''

total_credits.times do |i|
  is_first = (i % batch_size).zero?
  import_credits.() if is_first

  credit = credits_generator.call(with_expiration: i > 500_000)
  cols = credit.keys.join(', ') if cols.empty?
  values = credit.values.map { |v| Credit.connection.quote(v) }.join(', ')

  credits += ', ' if is_first
  credits += "(#{values})"
end

import_credits.()

User.where.not(id: Credit.select(:user_id).uniq).delete_all
