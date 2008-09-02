class PasswordSettingsController < ApplicationController
	before_filter :login_required

  # Change password view
  def index
		if (!current_user.identity_url.blank? && current_user.password.blank?)
			flash[:error] = "OpenID users cannot change their password."
			redirect_to user_path(current_user)	
		end
  end
  
  # Change password action  
  def create
		begin
			if current_user.change_password!(params[:old_password], params[:password], params[:password_confirmation])
	   		flash[:notice] = "Password successfully updated."
	    	redirect_to user_path(current_user)			
			else
				@old_password = nil
	      flash[:error] = "Your password was not changed, you old password may be incorrect."
	      render :action => 'index'
			end
		rescue Authentication::UserAbstraction::OpenidUser
			flash[:error] = "OpenID users cannot change their password."
			redirect_to user_path(current_user)
		rescue Authentication::UserAbstraction::PasswordMismatch
      @old_password = nil
			flash[:error] = "New password does not match the password confirmation."
      render :action => 'index'
		end
	end

end
