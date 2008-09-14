class OpenidSessionsController < SessionsController
	before_filter :login_prohibited

	def index
	
	end

	def new
		#	Display recaptcha only if the number of failed logins have 
		# exceeded the specified limit within a certain timeframe
		@bad_visitor = UserFailure.failure_check(request.remote_ip)
    respond_to do |format|
      format.html 
			format.js
    end
	end

end
