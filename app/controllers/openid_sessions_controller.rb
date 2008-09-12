class OpenidSessionsController < SessionsController
	before_filter :login_prohibited

	def index
	
	end

	def new
		#	Display recaptcha only if the number of failed logins have 
		# exceeded the specified limit within a certain timeframe
		@recaptcha = @bad_visitor
	end

end
