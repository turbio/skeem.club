class Transaction < ActiveRecord::Base
	belongs_to :from
	belongs_to :to

	enum reason: [:user_joined]
end
