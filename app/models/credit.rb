class Credit < ApplicationRecord
  belongs_to :user

  self.inheritance_column = nil

  scope :balance_by_user, -> { group(:user_id).sum(:amount) }
end
