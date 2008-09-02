class OpenidUsersController < ApplicationController
  before_filter :login_prohibited

	def new

	end

	def create
    logout_keeping_session!
    @user = OpenidUser.new(params[:user])
		@user.identity_url = params[:user][:identity_url]
    success = @user && @user.save
    if success && @user.errors.empty?
			session[:identity_url] = nil			
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or %s."
			flash[:error_item] = ["contact us", contact_site]
      render :action => 'new'
    end
	end

end

