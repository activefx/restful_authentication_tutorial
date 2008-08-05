class UsersController < ApplicationController
  before_filter :login_required, :only => [ :show, :edit, :update, :destroy, :enable, :password, :change ]

  def index
    @users = User.find(:all)
  end
   
  # This show action only allows users to view their own profile
  def show
    @user = current_user
  end  

  # render new.rhtml
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
            redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
			logger.warn "Invalid activation code from #{request.remote_ip} at #{Time.now.utc}"
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "User disabled"
    else
      flash[:error] = "There was a problem disabling this user."
    end
    redirect_to :action => 'index'
  end

  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "User enabled"
    else
      flash[:error] = "There was a problem enabling this user."
    end
      redirect_to :action => 'index'
  end

  # Change password view
  def password
  end
  
  # Change password action  
  def change
    if User.authenticate(current_user.login, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
        current_user.password_confirmation = params[:password_confirmation]
        current_user.password = params[:password]        
    		 if current_user.save
          flash[:notice] = "Password successfully updated."
          redirect_to show_user_path(current_user)
        else
          flash[:error] = "An error occured, your password was not changed."
          render :action => 'edit'
        end
      else
        flash[:error] = "New password does not match the password confirmation."
        (@old_password && params[:old_password]) = nil
        render :action => 'edit'      
      end
    else
      flash[:error] = "Your old password is incorrect."
		 (@old_password && params[:old_password]) = nil
      render :action => 'edit'
    end 
  end
end
