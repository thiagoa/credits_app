class User < ApplicationRecord
  def self.random
    new(name: FFaker::Name.name)
  end
end
