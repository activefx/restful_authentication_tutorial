class User::ActivationsController < ApplicationController
	before_filter :login_prohibited

  def activate
    logout_keeping_session!
		begin      
			if user = User.find_with_activation_code(params[:activation_code])
	      user.activate!
	      flash[:notice] = "Signup complete! Please sign in to continue."
	      redirect_to login_path
			else
				logger.warn "Invalid activation code from #{request.remote_ip} at #{Time.now.utc}"
	      flash[:error]  = "We couldn't find a user with that activation code, please check your email and try again, or %s."
				flash[:error_item] = ["request a new activation code", resend_activation_path]
	      redirect_to root_path
			end
		rescue Authentication::UserAbstraction::NoActivationCode
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to root_path
		rescue Authentication::UserAbstraction::AlreadyActivated
      flash[:notice] = "Your account has already been activated."
      redirect_to login_path
		end
  end

  # Enter email address to resend activation 
  def edit
  end

  # Resend activation action
  def update  
		begin  
	    if !params[:email].blank? && User.send_new_activation_code(params[:email])
	      flash[:notice] = "A new activation code has been sent to your email address."
	      redirect_to root_path
	    else				
	      flash[:error] = "There was a problem resending your activation code, please try again or %s."
				flash[:error_item] = ["contact us", contact_site]
	      redirect_to resend_activation_path
	    end 
		rescue Authentication::UserAbstraction::EmailNotFound
			logger.warn "Invalid email entered '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
			flash[:error] = "Could not find a user with that email address."
			redirect_to resend_activation_path
		end
  end

end
