class UsersController < ApplicationController
  before_filter :login_required, :only =>  [ :index, :show, :edit, :update, :destroy, 
																						 :enable, :password, :changepassword, :change ]
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
    @user = User.new(params[:user])
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
				flash[:error_item] = ["request a new activation code", new_code_path]
	      redirect_back_or_default('/')
			end
		rescue User::NoActivationCode
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
		rescue User::AlreadyActivated
      flash[:notice] = "Your account has already been activated."
      redirect_to login_path
		end
  end

  # Enter email address to recover password 
  def new_code
  end

  # Forgot password action
  def create_code  
		begin  
	    if User.send_new_code(params[:email])
	      flash[:notice] = "A new activation code has been sent to your email address."
	      redirect_to root_path
	    else				
	      flash[:error] = "There was a problem resending your activation code, please %s."
				#Replace root_path with your site's contact form.
				flash[:error_item] = ["contact us", root_path]
	      redirect_to new_code_path
	    end  
		rescue User::BlankEmail
			flash[:error] = "Please enter your email address."
			redirect_to new_code_path
		rescue User::EmailNotFound
			logger.warn "Invalid email entered '#{params[:email]}' from #{request.remote_ip} at #{Time.now.utc}"
			flash[:error] = "Could not find a user with that email address."
			redirect_to new_code_path
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
  end
  
  # Change password action  
  def change
    if User.authenticate(current_user.login, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) && !params[:password_confirmation].blank?)
        current_user.password_confirmation = params[:password_confirmation]
        current_user.password = params[:password]        
    		if current_user.save
          flash[:notice] = "Password successfully updated."
          redirect_to :action => 'show'
        else
					@old_password = nil
          flash[:error] = "An error occured, your password was not changed."
          render :action => 'changepassword'
        end
      else        
        @old_password = nil
				flash[:error] = "New password does not match the password confirmation."
        render :action => 'changepassword'      
      end
    else      
		  @old_password = nil
			flash[:error] = "Your old password is incorrect."
      render :action => 'changepassword'
    end 
  end
end
