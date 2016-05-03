class String
	def to_password_hash
		self + 'wew security'
	end
	def to_password_hash!
		replace to_password_hash
	end
end

class User < ActiveRecord::Base
	has_ancestry

	has_many :transactions_from, foreign_key: 'from_id', class_name: 'Transaction'
	has_many :transactions_to, foreign_key: 'to_id', class_name: 'Transaction'

	validates :name, presence: true,
		length: { minimum: 3 },
		uniqueness: { case_sensitive: false },
		format: { with: /\A[A-Za-z0-9]+\z/, message: "must be alphanumeric" }
	validates :password, presence: true

	before_save :hash_password_hook
	after_save :generate_transaction_tree

	def earned
		self.transactions_to.sum(:amount) - self.transactions_from.sum(:amount)
	end

	def transactions
		self.transactions_to + self.transactions_from
	end

	def self.authenticate(name, password)
		@hashed_password = password.to_password_hash
		User.where(
			"lower(name) = ? AND password = ?",
			name.downcase,
			@hashed_password).first
	end

	protected
		def hash_password_hook
			self.password.to_password_hash!
		end

		def generate_transaction_tree
			#user starts with 10_00
			Transaction.create(
				to_id: id,
				from_id: nil,
				amount: 10_00,
				reason: :user_joined)

			#user's 10_00 gets distributed to parents
			@initial_transaction = Transaction.create(
				to_id: parent.id,
				from_id: id,
				amount: 10_00,
				reason: :user_joined)

			distribute_wealth @initial_transaction
		end

		def distribute_wealth(transaction)
			@to, @from, @amount =
				if transaction.to.nil?
					[transaction.from.parent || return, transaction.from, transaction.amount]
				else
					[transaction.to.parent || return, transaction.to, transaction.amount / 2]
				end

			@subtrans = Transaction.create(
				parent_id: transaction.id,
				to_id: @to.id,
				from_id: @from.id,
				amount: @amount,
				reason: transaction.reason)

			distribute_wealth @subtrans
		end
end
