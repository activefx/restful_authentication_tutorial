class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account.'
    @body[:url]  = "http://#{APP_CONFIG['settings']['domain']}/activate/#{user.activation_code}" 
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://#{APP_CONFIG['settings']['domain']}/"
  end

  def forgot_password(user)
    setup_email(user)
    @subject    += 'You have requested to change your password.'
    @body[:url]  = "http://#{APP_CONFIG['settings']['domain']}/reset_password/#{user.password_reset_code}"
  end

  def reset_password(user)
    setup_email(user)
    @subject    += 'Your password has been reset.'
  end

	def invitation(invitation)
		setup_email(invitation)
	  @subject    += 'You have been invited to our private beta!'
		@body[:url] = "http://#{APP_CONFIG['settings']['domain']}/signup/#{invitation.token}"
	  invitation.update_attribute(:sent_at, Time.now)
	end

  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = APP_CONFIG['mail']['sender']
      @subject     = "#{APP_CONFIG['settings']['name']} - "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
