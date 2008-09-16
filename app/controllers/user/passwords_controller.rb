class User::PasswordsController < ApplicationController
  before_filter :login_prohibited

  # Enter email address to recover password 
  def new
  end

  # Forgot password action
  def create    
    if SiteUser.find_for_forget(params[:email])    
      flash[:notice] = "A password reset link has been sent to your email address."
      redirect_to root_path
    else
      flash.now[:notice] = "A password reset link was not sent, you may have enetered an invalid email address."
      render :action => 'new'
    end  
  end
  
  # Action triggered by clicking on the /reset_password/:id link recieved via email
  # Checks that the id code matches a user in the database
  # Then if everything checks out, shows the password reset fields
  def edit
		@bad_visitor = UserFailure.failure_check(request.remote_ip)
		if params[:id].nil?
			flash[:error] = "The password reset code was missing."
			redirect_to root_path
		end
  end
    
  # Reset password action /reset_password/:id
  def update
		@bad_visitor = UserFailure.failure_check(request.remote_ip)
		if @bad_visitor && !verify_recaptcha
			flash[:error] = "The captcha was incorrect, please follow the link from your email again."
			redirect_to root_path
			return
		end
    SiteUser.find_and_reset_password(params[:password], params[:password_confirmation], 
			params[:reset_code]) do |error, message, path, failure|
			if path
				UserFailure.record_failure(request.remote_ip, 
					request.env['HTTP_USER_AGENT'], "passwordreset", nil) if failure
				flash[error] = message
				redirect_to send(path)
			else
				flash.now[error] = message
				render :action => 'edit', :id => params[:id]
			end
		end
	end
    
end


