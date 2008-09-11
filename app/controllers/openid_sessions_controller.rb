class OpenidSessionsController < SessionsController

	def new
		#	Display recaptcha only if the number of failed logins have 
		# exceeded the specified limit within a certain timeframe
		@recaptcha = @bad_visitor
	end

end
