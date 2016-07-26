class User < ApplicationRecord
  has_many :credits

  def self.random
    new(name: FFaker::Name.name)
  end
end
