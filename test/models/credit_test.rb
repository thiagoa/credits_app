require 'test_helper'

class CreditTest < ActiveSupport::TestCase
  test 'balance by user' do
    john = create_user('John')
    paul = create_user('Paul')

    create_credit john, 50
    create_credit john, 25
    create_credit john, -5
    create_credit paul, 25
    create_credit paul, 9

    balance = Credit.balance_by_user

    assert_equal({ john.id => 70, paul.id => 34 }, balance)
  end

  test 'balance by user does not return balance for users with no credits' do
    john = create_user('John')
    paul = create_user('Paul')

    create_credit john, 50

    balance = Credit.balance_by_user

    refute_includes balance.keys, paul.id
    assert_includes balance.keys, john.id
  end

  def create_user(name)
    User.create!(name: name)
  end

  def create_credit(user, amount)
    Credit.create(type: 'Credit', user: user, amount: amount)
  end
end
