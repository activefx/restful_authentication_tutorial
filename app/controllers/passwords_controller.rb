class PasswordsController < ApplicationController
  
  # Enter email address to recover password 
  def new
  end

  # Forgot password action
  def create    
    if @user = User.find_for_forget(params[:email])
      @user.forgot_password
      @user.save      
      flash[:notice] = "A password reset link has been sent to your email address."
      redirect_to root_path
    else
			logger.warn "Invalid email entered '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
      flash[:notice] = "Could not find a user with that email address."
      render :action => 'new'
    end  
  end
  
  # Action triggered by clicking on the /reset_password/:id link recieved via email
  # Makes sure the id code is included
  # Checks that the id code matches a user in the database
  # Then if everything checks out, shows the password reset fields
  def edit
    if params[:id].nil?
			flash[:error] = "The password reset code was missing.  Please follow the URL from your email, or enter your email below to resend the reset code."
      render :action => 'new'
      return
    end
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
  rescue
    logger.warn "Invalid password reset code from #{request.remote_ip} at #{Time.now.utc}"
    flash[:notice] = "Invalid password reset code, please check your email and try again."
    redirect_to root_path
  end
    
  # Reset password action /reset_password/:id
  # Checks once again that an id is included and makes sure that the password field isn't blank
  def update
    if params[:id].nil?
			flash[:error] = "The password reset code was missing.  Please follow the URL from your email, or enter your email below to resend the reset code."
      render :action => 'new'
      return
    end
    if (params[:password].blank? || params[:password_confirmation].blank?)
      flash[:notice] = "Password fields cannot be blank."
      render :action => 'edit', :id => params[:id]
      return
    end
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
    if (params[:password] == params[:password_confirmation])
      @user.password_confirmation = params[:password_confirmation]
      @user.password = params[:password]
      if @user.save
			  @user.reset_password        
        flash[:notice] = "Password reset." 
			else
				flash[:notice] = "There was a problem resetting your password."
			end
    else
      flash[:notice] = "Password and password confirmation did not match."
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


