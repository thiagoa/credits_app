Credit.delete_all
User.delete_all

User.import(30_000.times.map { User.random })
credits_generator = RandomCreditsGenerator.new(user_ids: User.pluck(:id))

TOTAL_CREDITS = 1_000_000
BATCH_SIZE = 20_000

cols = ''
credits = ''

import_credits = -> {
  sql = "INSERT INTO credits(#{cols}, updated_at) VALUES #{credits}"
  Credit.connection.execute(sql) unless credits.empty?

  credits = ''
}

TOTAL_CREDITS.times do |i|
  is_first = (i % BATCH_SIZE).zero?
  import_credits.() if is_first

  credit = credits_generator.call(with_expiration: i > 30_000)
  cols = credit.keys.join(', ') if cols.empty?
  values = credit.values.map { |v| Credit.connection.quote(v) }.join(', ')
  values += ", #{Credit.connection.quote(credit[:created_at])}"

  credits += %{#{is_first ? '' : ', '}(#{values})}
end

import_credits.()

User.where.not(id: Credit.select(:user_id).uniq).delete_all
