class User::ActivationsController < ApplicationController
	before_filter :login_prohibited

  def activate
    logout_keeping_session!
		User.find_with_activation_code(params[:activation_code]) do |error, message, path|
			flash[:error_item] = ["request a new activation code", resend_activation_path]
			flash[error] = message
			redirect_to send(path)
		end
  end

  # Enter email address to resend activation 
  def new
  end

  # Resend activation action
  def create  
		User.send_new_activation_code(params[:email]) do |error, message, path|
			flash[:error_item] = ["contact us", contact_site]
			flash[error] = message
			redirect_to send(path)
		end
	end

end
