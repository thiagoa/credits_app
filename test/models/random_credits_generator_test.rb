require 'test_helper'

class RandomCreditsGeneratorTest < ActiveSupport::TestCase
  setup { srand 61158 }
  teardown { srand 0 }

  test 'on first call generates a 1_000 amount with correct credit attributes' do
    initial_created_at = Time.new(2017, 1, 1, 1, 2)
    generator = RandomCreditsGenerator.new(
      user_ids: [1],
      initial_balances: {},
      initial_created_at: initial_created_at,
      created_at_increment_samples: (1..2)
    )

    credit_attrs = generator.call

    assert_equal 1_000, credit_attrs[:amount]
    assert_equal 1, credit_attrs[:user_id]
    assert_equal 'Credit', credit_attrs[:type]
    assert credit_attrs[:processed]
    assert_nil credit_attrs[:expires_at]
  end

  test 'increments created_at in each call' do
    initial_created_at = Time.new(2017, 1, 1, 1, 2)
    generator = RandomCreditsGenerator.new(
      user_ids: [1],
      initial_balances: {},
      initial_created_at: initial_created_at,
      created_at_increment_samples: (1..2)
    )

    first_created_at = generator.call[:created_at]
    second_created_at = generator.call[:created_at]

    assert_operator first_created_at, :<=, initial_created_at + 2
    assert_operator first_created_at, :>, initial_created_at
    assert_operator second_created_at, :<=, first_created_at + 2
    assert_operator second_created_at, :>, first_created_at
  end

  test 'with_expiration option generates positive unprocessed amounts with 1 year expiration or negative processed amounts without expiration' do
    initial_created_at = Time.new(2017, 1, 1, 1, 2)
    generator = RandomCreditsGenerator.new(
      user_ids: [1],
      initial_balances: {},
      initial_created_at: initial_created_at
    )

    results = 10.times.map { generator.call(with_expiration: true) }

    assert results.find { |attrs| attrs[:amount] > 0 }
    assert results.find { |attrs| attrs[:amount] < 0 }
    results.each do |result|
      if result[:amount] > 0
        assert_equal Date.new(2018, 1, 1), result[:expires_at]
        refute result[:processed]
      else
        assert_nil result[:expires_at]
        assert result[:processed]
      end
    end
  end

  test 'picks users randomly' do
    generator = RandomCreditsGenerator.new(
      user_ids: [1, 2, 3],
      initial_balances: {}
    )

    result_user_ids = 100.times.map { generator.call[:user_id] }.uniq

    assert_equal [1, 2, 3], result_user_ids.sort
  end

  test 'never generates negative balances' do
    generator = RandomCreditsGenerator.new(
      user_ids: [1, 2],
      initial_balances: {}
    )
    balances = Hash.new(0)
    intermediary_balances = Hash.new { |hash, key| hash[key] = [] }

    100.times do
      credit_attrs = generator.call
      user_id = credit_attrs[:user_id]

      balances[user_id] += credit_attrs[:amount]
      intermediary_balances[user_id] << balances[user_id]
    end

    assert intermediary_balances[1].all? { |balance| balance >= 0 }
    assert intermediary_balances[2].all? { |balance| balance >= 0 }
  end
end
