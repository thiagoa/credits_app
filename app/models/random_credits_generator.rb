class RandomCreditsGenerator
  def initialize(
    user_ids:,
    initial_balances: nil,
    initial_created_at: Time.new(2012, 2, 2),
    created_at_increment_samples: (1..80)
  )
    @user_ids = user_ids
    @initial_balances = initial_balances
    @created_at = initial_created_at
    @created_at_increment_samples = created_at_increment_samples.to_a
  end

  def call(**options)
    user_id, amount = pick_random_user_id_and_amount

    add_to_balance_cache(user_id, amount)
    generate_credit(user_id, amount, options)
  end

  private

  def pick_random_user_id_and_amount
    user_id = @user_ids.sample
    amount = generate_random_amount(user_id)

    [user_id, amount]
  end

  def add_to_balance_cache(user_id, amount)
    balances[user_id] += amount
  end

  def generate_random_amount(user_id)
    RandomAmountGenerator.new(balances[user_id]).call
  end

  def balances
    @balances ||= Hash.new(0).merge(initial_balances)
  end

  def initial_balances
    @initial_balances || Credit.balance_by_user
  end

  def generate_credit(user_id, amount, options)
    created_at = next_created_at
    with_expiration = options[:with_expiration] && amount > 0
    processed = !with_expiration
    expires_at = (created_at + 1.year).to_date if with_expiration

    {
      type: 'Credit',
      user_id: user_id,
      amount: amount,
      created_at: created_at,
      expires_at: expires_at,
      processed: processed
    }
  end

  def next_created_at
    @created_at += @created_at_increment_samples.sample
  end

  class RandomAmountGenerator
    CREDIT_TYPES = %i(positive negative)
    POSITIVE_CREDIT_AMOUNT = 1_000

    def initialize(balance)
      @balance = balance
    end

    def call
      begin
        amount = pick_random_amount
      end until valid_balance_preview?(amount)

      amount
    end

    private

    def pick_random_amount
      if CREDIT_TYPES.sample == :positive
        POSITIVE_CREDIT_AMOUNT
      else
        pick_random_negative_amount
      end
    end

    def pick_random_negative_amount
      return 0 if @balance.zero?

      -(50..@balance).step(50).to_a.sample
    end

    def valid_balance_preview?(amount)
      amount.nonzero? || @balance + amount < 0
    end
  end

  private_constant :RandomAmountGenerator
end
