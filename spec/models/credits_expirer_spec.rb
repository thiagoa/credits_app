require 'rails_helper'

RSpec.describe CreditsExpirer do
  _ = nil

  context 'when a user has no credits' do
    it 'does not expire anything' do
      joe = create_user

      CreditsExpirer.call(Date.current)

      expect(joe).to have_balance 0
      expect(joe).to have_no_reversal_credit
    end
  end

  context 'when a user has no debits' do
    it 'expires all credits' do
      joe = create_user

      create_credit joe, 1_000, '2016-07-02', '2017-07-02'

      CreditsExpirer.call('2017-07-02')

      expect(joe).to have_balance 0
      expect(joe).to have_new_reversal_credit -1_000
    end
  end

  context 'when user has credits already processed' do
    it 'does not create reversal credits' do
      joe = create_user

      create_credit joe, 1_000, '2016-07-02', '2017-07-02', _, processed: true

      CreditsExpirer.call('2017-07-02')

      expect(joe).to have_balance 1_000
      expect(joe).to have_no_reversal_credit
    end
  end

  context 'when a user has one credit to expire' do
    it 'expires the credit and returns the correct balance' do
      joe = create_user

      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, -500,  '2016-06-01', _
      create_credit joe, 1_000, '2016-07-02', '2017-07-02'

      CreditsExpirer.call('2017-01-05')

      expect(joe).to have_balance 1000
      expect(joe).to have_new_reversal_credit -500
    end
  end

  context 'with two users' do
    context 'when credits of both users are due the same day' do
      it "expires all credits and returns correct balances" do
        joe = create_user
        bob = create_user

        create_credit joe, 1_000, '2016-01-05', '2017-01-05'
        create_credit bob, 700,   '2016-01-05', '2017-01-05'
        create_credit joe, -500,  '2016-06-01', _
        create_credit joe, 1_000, '2016-07-02', '2017-07-02'

        CreditsExpirer.call('2017-01-05')

        expect(joe).to have_balance 1000
        expect(joe).to have_new_reversal_credit -500
        expect(bob).to have_balance 0
        expect(bob).to have_new_reversal_credit -700
      end
    end

    context 'when only one user has due credits' do
      it "expires credits from that user and keeps other one's balance intact" do
        joe = create_user
        bob = create_user

        create_credit joe, 1_000, '2016-01-05', '2017-01-05'
        create_credit bob, 700,   '2016-01-06', '2017-01-06'
        create_credit joe, -500,  '2016-06-01', _
        create_credit joe, 1_000, '2016-07-02', '2017-07-02'

        CreditsExpirer.call('2017-01-05')

        expect(joe).to have_balance 1000
        expect(joe).to have_new_reversal_credit -500
        expect(bob).to have_balance 700
      end
    end
  end

  context 'when a user has two credits which expire the same day' do
    it 'expires both credits and returns the correct balance' do
      joe = create_user

      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, -500,  '2016-06-01', _
      create_credit joe, 1_000, '2016-07-02', '2017-07-02'

      CreditsExpirer.call('2017-01-05')

      expect(joe).to have_balance 1_000
      expect(joe).to have_new_reversal_credit -1_500
    end
  end

  context 'when a user has credits without expiration date' do
    it 'does not factor in the amount without expiration date' do
      joe = create_user

      create_credit joe, 800,   '2016-01-04', _
      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, -500,  '2016-06-01', _
      create_credit joe, 1_000, '2016-07-02', '2017-07-02'

      CreditsExpirer.call('2017-01-05')

      expect(joe).to have_balance 1_800
      expect(joe).to have_new_reversal_credit -500
    end
  end

  context 'when a user has amounts prior to first credit with expiration date' do
    it 'does not factor in those amounts' do
      joe = create_user

      create_credit joe, 800,   '2016-01-02', _
      create_credit joe, -200,  '2016-01-04', _
      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, -500,  '2016-06-01', _
      create_credit joe, 1_000, '2016-07-02', '2017-07-02'

      CreditsExpirer.call('2017-01-05')

      expect(joe).to have_balance 1_600
      expect(joe).to have_new_reversal_credit -500
    end
  end

  context 'when a user with no due credits has unprocessed credits' do
    it 'older credits gets expired and marked as processed' do
      joe = create_user
      bob = create_user

      create_credit bob, 1_000, '2015-12-05', '2016-12-05'
      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, -500,  '2016-06-01', _
      create_credit joe, 1_000, '2016-07-02', '2017-07-02'

      CreditsExpirer.call('2017-07-02')

      expect(bob).to have_balance 0
      expect(joe).to have_balance 0
      expect(bob.credits.first).to be_processed
    end
  end

  context 'with all main cases' do
    it 'expires all credits correctly' do
      joe = create_user
      bob = create_user

      create_credit bob, 200,   '2016-01-02', _
      create_credit joe, 800,   '2016-01-02', _
      create_credit bob, -100,  '2016-01-02', _
      create_credit bob, 900,   '2016-01-03', '2017-01-03'
      create_credit bob, -100,  '2016-01-04', _
      create_credit joe, -200,  '2016-01-04', _
      create_credit bob, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, 1_000, '2016-01-05', '2017-01-05'
      create_credit joe, -500,  '2016-06-01', _
      create_credit joe, 1_000, '2016-07-02', '2017-07-02'
      create_credit joe, -800,  '2016-06-01', _
      create_credit joe, 1_000, '2016-09-05', '2017-09-05'

      expect(joe).to have_balance 2_300
      expect(bob).to have_balance 1_900

      CreditsExpirer.call('2017-01-03')

      expect(joe).to have_balance 2_300
      expect(bob).to have_balance 1_100

      CreditsExpirer.call('2017-01-05')

      expect(joe).to have_balance 2_300
      expect(bob).to have_balance 100

      CreditsExpirer.call('2017-07-02')

      expect(joe).to have_balance 1_600
      expect(bob).to have_balance 100

      CreditsExpirer.call('2017-09-05')

      expect(joe).to have_balance 600
      expect(bob).to have_balance 100

      create_credit joe, 500,  '2016-10-10', '2017-10-10'
      create_credit joe, -200, '2016-10-10', _
      create_credit bob, 600,  '2016-10-10', '2017-10-10'
      create_credit bob, 200,  '2016-11-11', '2017-11-11'

      expect(joe).to have_balance 900
      expect(bob).to have_balance 900

      CreditsExpirer.call('2017-10-10')

      expect(joe).to have_balance 600
      expect(bob).to have_balance 300
    end
  end

  def create_user
    user = User.random
    user.save!
    user
  end

  def create_credit(user, amount, created_at, expires_at = nil, type = nil, **attrs)
    defaults = {
      amount: amount,
      expires_at: expires_at,
      type: 'Credit',
      user: user,
      processed: expires_at.blank?
    }
    credit = Credit.create!(defaults.merge(attrs))
    credit.update_column(:created_at, created_at)
    credit
  end
end

RSpec::Matchers.define :have_new_reversal_credit do |amount|
  def last_credit(user)
    @last_credit ||= user.credits.order(id: :desc).first
  end

  match do |user|
    credit = last_credit(user)

    credit.amount == amount && credit.type == 'Reversal'
  end

  failure_message do |user|
    "expected last credit to be a reversal with amount #{amount} "\
      "but was #{last_credit(user).amount}"
  end
end

RSpec::Matchers.define :have_balance do |amount|
  def balance(user)
    @balance ||= user.credits.sum(:amount)
  end

  match do |user|
    balance(user) == amount
  end

  failure_message do |user|
    "expected user to have balance #{amount} but has #{balance(user)}"
  end
end

RSpec::Matchers.define :have_no_reversal_credit do |amount|
  def last_credit(user)
    @last_credit ||= user.credits.last
  end

  match do |user|
    user.credits.empty? || last_credit(user).type != 'CreditReversal'
  end

  failure_message do |user|
    "expected user to have no reversal credit, but has "\
      "one of #{last_credit(user).amount}"
  end
end
