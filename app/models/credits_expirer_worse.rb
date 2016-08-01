class CreditsExpirerWorse
  def self.call(*args)
    new(*args).call
  end

  def initialize(expiration_date)
    @expiration_date = expiration_date
  end

  def call
    Credit.transaction do
      expire_due_credits
      mark_credits_as_processed
    end
  end

  private

  def expire_due_credits
    user_ids_with_credits_to_expire.each do |user_id|
      amount_to_expire = calculate_amount_to_expire(user_id)

      if amount_to_expire > 0
        create_reversal_credit(user_id, amount_to_expire)
      end
    end
  end

  def user_ids_with_credits_to_expire
    @credits_to_expire ||= credits_to_process.distinct.pluck(:user_id)
  end

  def credits_to_process
    @credits_to_process ||= Credit
      .where('expires_at <= ?', @expiration_date)
      .where(processed: false)
      .where.not(user_id: nil)
  end

  def calculate_amount_to_expire(user_id)
    positive = total_credits_until_current_expiration_date(user_id)
    negative = total_debits_starting_from_first_credit_that_expires(user_id)

    positive + (negative || 0)
  end

  def total_credits_until_current_expiration_date(user_id)
    Credit
      .where('expires_at <= ?', @expiration_date)
      .where(user_id: user_id)
      .sum(:amount)
  end

  def total_debits_starting_from_first_credit_that_expires(user_id)
    Credit
      .from('credits AS c')
      .where('c.created_at >= (?)', creation_date_of_first_credit_that_expires)
      .where('c.user_id = ?', user_id)
      .where('c.amount < 0')
      .sum('c.amount')
  end

  def creation_date_of_first_credit_that_expires
    Credit
      .select('MIN(created_at)')
      .where('credits.user_id = c.user_id')
      .where.not(expires_at: nil)
  end

  def create_reversal_credit(user_id, amount)
    Credit.create!(user_id: user_id, type: 'Reversal', amount: -amount)
  end

  def mark_credits_as_processed
    credits_to_process.update_all processed: true
  end
end
