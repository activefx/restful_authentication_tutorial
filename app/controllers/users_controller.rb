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
			flash[:error_item] = ["contact us", contact_site]
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

end
