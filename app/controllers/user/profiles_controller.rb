class User::ProfilesController < ApplicationController
  before_filter :login_required, :only =>  [ :show, :edit, :update ]
	before_filter :login_prohibited, :only => [:new, :create]
   
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
		# WARNING
		# Because role ids are an accessible attribute, anytime you 
		# use User.new you need to assign the params individually
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
			flash[:error_item] = ["contact us", contact_site]
      render :action => 'new'
    end
  end

	def edit
		@user = current_user
		if !@user.identity_url.blank? && @user.crypted_password.blank?
			redirect_to edit_user_openid_account_path
		end
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

end
