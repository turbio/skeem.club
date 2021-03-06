require 'bigdecimal'

module BitcoinHelper
	Config = Rails.configuration.payment

	def new_address
		req = Net::HTTP::Post.new('/new')
		req.basic_auth Config['user'], Config['password']

		http = Net::HTTP.start(Config['host'], Config['port'])
		http.request(req).body[1...-1]
	end

	def address_info(address)
		req = Net::HTTP::Get.new("/#{address}?confirmations=#{Config['confirmations']}")
		req.basic_auth Config['user'], Config['password']

		http = Net::HTTP.start(Config['host'], Config['port'])
		res = JSON.parse(http.request(req).body)

		{
			balance: BigDecimal.new(res['balance']),
			transactions: res['transactions'].map do |t|
				{ amount: t['amount'], confirmations: t['confirmations'] }
			end
		}
	end
end
