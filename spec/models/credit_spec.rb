require 'rails_helper'

RSpec.describe Credit do
  it 'returns the total balance of each user' do
    john = create_user('John')
    paul = create_user('Paul')

    create_credits john, [50, 25, -5]
    create_credits paul, [25, 9]

    balance = Credit.balance_by_user

    expect(balance).to eq(john.id => 70, paul.id => 34)
  end

  context 'when a user has no credits' do
    it 'does not return a balance for that user' do
      john = create_user('John')
      paul = create_user('Paul')

      create_credits john, [50]

      balance = Credit.balance_by_user

      expect(balance.keys).to_not include paul.id
      expect(balance.keys).to include john.id
    end
  end

  def create_user(name)
    User.create!(name: name)
  end

  def create_credits(user, amounts)
    amounts.each do |amount|
      Credit.create! type: 'Credit', user: user, amount: amount
    end
  end
end
