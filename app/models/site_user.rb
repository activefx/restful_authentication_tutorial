class SiteUser < User
	include Authentication::ByPassword

	# Password authentication method, only available to SiteUsers
	# yield user, message, item_msg, item_path
	def self.authenticate(login, password, &block)
		yield nil, "Username and password cannot be blank.", nil, nil and
			return if (login.blank? || password.blank?)
		u = find :first, :conditions => ['login = ?', login], :include => :roles
		yield nil, "Could not log you in as '#{CGI.escapeHTML(login)}', your username or password is incorrect.", nil, 
			nil and return unless (u && u.authenticated?(password))
		case
		when !u.active?
			yield nil, "Your account has not been activated, please check your email or %s.", "request a new activation 				code", "resend_activation_path"
		when !u.enabled?
			yield nil, "Your account has been disabled, please %s.", "contact the administrator", "contact_site"
		else
			yield u, nil, nil, nil
		end
	end

	# Password reset method, only available to SiteUsers
	# yield error, message, path, failure
	def self.find_and_reset_password(password, password_confirmation, reset_code, &block) 
		u = find :first, :conditions => ['password_reset_code = ?', reset_code]
		case 
		when (reset_code.blank? || u.nil?)
			yield :error, "Invalid password reset code, please check your email and try again.", "root_path", true
		when (password.blank? || (password != password_confirmation))
			yield :error, "Password and password confirmation did not match.", nil, false
		else
			u.password = password
			u.password_confirmation = password_confirmation
			if u.save
				u.reset_password!
				yield :notice, "Password reset.", "login_path", false
			else
				yield :error, "There was a problem resetting your password.", "root_path", false
			end				
		end					
	end

	# Password reset method, only available to SiteUsers
  def self.find_for_forget(email)
    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL', email]
		return false if (email.blank? || u.nil? || (!u.identity_url.blank? && u.password.blank?))
		(u.forgot_password && u.save) ? true : false
  end

end
