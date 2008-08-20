class ActionController::CgiRequest
	def relative_url_root
	  @@relative_url_root ||= case
	    when @env["RAILS_RELATIVE_URL_ROOT"]
	      @env["RAILS_RELATIVE_URL_ROOT"]
	    when server_software == 'apache'
	      @env["SCRIPT_NAME"].to_s.sub(/\/dispatch\.(fcgi|rb|cgi)$/, '')
	    else
	      ''
	  end
	end
end
