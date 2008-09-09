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
			logger.warn "Password reset not sent with email '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
      flash.now[:notice] = "A password reset link was not sent, you may have enetered an invalid email address."
      render :action => 'new'
    end  
  end
  
  # Action triggered by clicking on the /reset_password/:id link recieved via email
  # Checks that the id code matches a user in the database
  # Then if everything checks out, shows the password reset fields
  def edit
    @user = SiteUser.find_with_password_reset_code(params[:id])
  rescue
    logger.warn "Invalid password reset code from #{request.remote_ip} at #{Time.now.utc}"
    flash[:notice] = "Invalid password reset code, please check your email and try again."
    redirect_to root_path
  end
    
  # Reset password action /reset_password/:id
  def update
    @user = SiteUser.find_with_password_reset_code(params[:reset_code]) 
    if (params[:password] == params[:password_confirmation])
      @user.password_confirmation = params[:password_confirmation]
      @user.password = params[:password]
      if (!params[:password].blank? && @user.save)
			  @user.reset_password!        
        flash[:notice] = "Password reset." 
			else
				flash[:notice] = "There was a problem resetting your password."
			end
    else
      flash.now[:notice] = "Password and password confirmation did not match."
      render :action => 'edit', :id => params[:id]
      return
    end  
    redirect_to login_path
  rescue
    logger.warn "Invalid password reset code from #{request.remote_ip} at #{Time.now.utc}"
    flash[:notice] = "Invalid password reset code, please check your email and try again."
    redirect_to root_path
  end
    
end


