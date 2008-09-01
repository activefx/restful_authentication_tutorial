class UsersController < ApplicationController
  before_filter :login_required, :only =>  [ :index, :show, :edit, :update, :destroy, 
																						 :enable, :password, :changepassword, :change ]
	before_filter :login_prohibited, :only => [:new, :create]
	require_role :admin, :only => [ :index, :destroy, :enable ]

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
		#WARNING
		#Because role ids are an accessible attribute, anytime you 
		#use User.new you need to assign the params individually
    @user = User.new(:login => params[:user][:login],
										 :email => params[:user][:email],
										 :name => params[:user][:name],
										 :password => params[:user][:password],
										 :password_confirmation => params[:user][:password_confirmation])
    success = @user && @user.save
    if success && @user.errors.empty?
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or %s."
			#Replace root_path with your site's contact form.
			flash[:error_item] = ["contact us", root_path]
      render :action => 'new'
    end
  end

	def edit
		@user = current_user
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = "Profile updated."
      redirect_to :action => 'show'
    else
			flash[:error] = "There was a problem updating your profile."
      render :action => 'edit'
    end
  end


  def activate
    logout_keeping_session!
		begin
      user = User.find_with_activation_code(params[:activation_code])
			if user
	      user.activate!
	      flash[:notice] = "Signup complete! Please sign in to continue."
	      redirect_to login_path
			else
				logger.warn "Invalid activation code from #{request.remote_ip} at #{Time.now.utc}"
	      flash[:error]  = "We couldn't find a user with that activation code, please check your email and try again, or %s."
				flash[:error_item] = ["request a new activation code", resend_activation_path]
	      redirect_back_or_default('/')
			end
		rescue Authentication::UserAbstraction::NoActivationCode
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
		rescue Authentication::UserAbstraction::AlreadyActivated
      flash[:notice] = "Your account has already been activated."
      redirect_to login_path
		end
  end

  # Enter email address to resend activation 
  def new_code
  end

  # Resend activation action
  def create_code  
		begin  
	    if !params[:email].blank? && User.send_new_activation_code(params[:email])
	      flash[:notice] = "A new activation code has been sent to your email address."
	      redirect_to root_path
	    else				
	      flash[:error] = "There was a problem resending your activation code, please %s."
				#Replace root_path with your site's contact form.
				flash[:error_item] = ["contact us", root_path]
	      redirect_to resend_activation_path
	    end 
		rescue Authentication::UserAbstraction::EmailNotFound
			logger.warn "Invalid email entered '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
			flash[:error] = "Could not find a user with that email address."
			redirect_to resend_activation_path
		end
  end

  def destroy
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "User disabled."
    else
      flash[:error] = "There was a problem disabling this user."
    end
    redirect_to :action => 'index'
  end

  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "User enabled."
    else
      flash[:error] = "There was a problem enabling this user."
    end
    redirect_to :action => 'index'
  end

  # Change password view
  def changepassword
		if (!current_user.identity_url.blank? && current_user.password.blank?)
			flash[:error] = "OpenID users cannot change their password."
			redirect_to :action => 'show'
		end
  end
  
  # Change password action  
  def change
		begin
			if current_user.change_password(params[:old_password], params[:password], params[:password_confirmation])
	   		flash[:notice] = "Password successfully updated."
	    	redirect_to :action => 'show'			
			else
				@old_password = nil
	      flash[:error] = "Your password was not changed, you old password may be incorrect."
	      render :action => 'changepassword'
			end
		rescue Authentication::UserAbstraction::OpenidUser
			flash[:error] = "OpenID users cannot change their password."
			redirect_to :action => 'show'
		rescue Authentication::UserAbstraction::PasswordMismatch
      @old_password = nil
			flash[:error] = "New password does not match the password confirmation."
      render :action => 'changepassword'
		end
	end

end
