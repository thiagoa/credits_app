class CreditsExpirerOneQuery
  def self.call(*args)
    new(*args).call
  end

  def initialize(expiration_date)
    @expiration_date = expiration_date
  end

  def call
    Credit.transaction do
      create_reversal_credits
      mark_credits_as_processed
    end
  end

  private

  def create_reversal_credits
    Credit.connection.execute(
      "INSERT INTO credits(amount, user_id, type, created_at, updated_at)
      #{reversal_credits_records.to_sql}"
    )
  end

  def reversal_credits_records
    amounts_sum = '-(positive.amount + COALESCE(negative.amount, 0))'

    columns = [
      "#{amounts_sum} AS amount",
      'positive.user_id',
      "'Reversal' AS type",
      'NOW() AS created_at',
      'NOW() AS updated_at'
    ]

    positive_with_negative = <<-SQL
      LEFT JOIN (#{negative_credits.to_sql}) negative
      ON positive.user_id = negative.user_id
    SQL

    Credit
      .select(*columns)
      .from(positive_credits, :positive)
      .joins(positive_with_negative)
      .where("#{amounts_sum} < 0")
  end

  def positive_credits
    Credit
      .select("SUM(amount) AS amount, user_id")
      .where('expires_at <= ?', @expiration_date)
      .where('user_id IN (?)', user_ids_with_credits_to_process)
      .group(:user_id)
  end

  def negative_credits
    Credit
      .select('SUM(amount) as amount, user_id')
      .from('credits AS negative')
      .where('user_id IN (?)', user_ids_with_credits_to_process)
      .where('created_at >= (?)', creation_date_of_first_expiring_credit)
      .where('amount < 0')
      .group(:user_id)
  end

  def user_ids_with_credits_to_process
    @user_ids_with_credits_to_process ||= credits_to_process
      .uniq
      .select(:user_id)
  end

  def credits_to_process
    @credits_to_process ||= Credit
      .where('expires_at <= ?', @expiration_date)
      .where(processed: false)
      .where.not(user_id: nil)
  end

  def creation_date_of_first_expiring_credit
    Credit
      .select('MIN(created_at)')
      .where('credits.user_id = negative.user_id')
      .where.not(expires_at: nil)
  end

  def mark_credits_as_processed
    credits_to_process.update_all processed: true
  end
end
