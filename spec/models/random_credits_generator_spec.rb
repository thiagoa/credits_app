require 'rails_helper'

RSpec.describe RandomCreditsGenerator do
  before { srand 61158 }
  after { srand }

  context 'when called once' do
    it 'generates a 1_000 amount with correct credit attributes' do
      initial_created_at = Time.new(2017, 1, 1, 1, 2)
      generator = RandomCreditsGenerator.new(
        user_ids: [1],
        initial_balances: {},
        initial_created_at: initial_created_at,
        created_at_increment_samples: (1..2)
      )

      credit_attrs = generator.call

      expect(credit_attrs[:amount]).to eq 1_000
      expect(credit_attrs[:user_id]).to eq 1
      expect(credit_attrs[:type]).to eq 'Credit'
      expect(credit_attrs[:processed]). to eq true
      expect(credit_attrs[:expires_at]).to be_nil
    end
  end

  it 'increments created_at date in each call' do
    initial_created_at = Time.new(2017, 1, 1, 1, 2)
    generator = RandomCreditsGenerator.new(
      user_ids: [1],
      initial_balances: {},
      initial_created_at: initial_created_at,
      created_at_increment_samples: (1..2)
    )

    first_created_at = generator.call[:created_at]
    second_created_at = generator.call[:created_at]

    expect(first_created_at).to be <= initial_created_at + 2
    expect(first_created_at).to be > initial_created_at
    expect(second_created_at).to be <= first_created_at + 2
    expect(second_created_at).to be > first_created_at
  end

  context 'when passing with_expiration option' do
    it 'generates positive amounts valid for 1 year or negative amounts without expiration' do
      initial_created_at = Time.new(2017, 1, 1, 1, 2)
      generator = RandomCreditsGenerator.new(
        user_ids: [1],
        initial_balances: {},
        initial_created_at: initial_created_at
      )

      results = 10.times.map { generator.call(with_expiration: true) }

      expect(results.find { |attrs| attrs[:amount] > 0 }).to be_truthy
      expect(results.find { |attrs| attrs[:amount] < 0 }).to be_truthy

      results.each do |result|
        if result[:amount] > 0
          expect(result[:expires_at]).to eq Date.new(2018, 1, 1)
          expect(result[:processed]).to eq false
        else
          expect(result[:expires_at]).to be_nil
          expect(result[:processed]).to eq true
        end
      end
    end
  end

  it 'picks users randomly' do
    generator = RandomCreditsGenerator.new(
      user_ids: [1, 2, 3],
      initial_balances: {}
    )

    result_user_ids = 100.times.map { generator.call[:user_id] }.uniq

    expect(result_user_ids.sort).to eq [1, 2, 3]
  end

  it 'never generates negative balances' do
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

    expect(intermediary_balances[1].all? { |balance| balance >= 0 }).to be_truthy
    expect(intermediary_balances[2].all? { |balance| balance >= 0 }).to be_truthy
  end
end
