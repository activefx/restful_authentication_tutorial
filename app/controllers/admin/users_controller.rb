class Admin::UsersController < ApplicationController
	before_filter :login_required
	require_role :admin

  def index
    @users = User.administrative_member_list(params[:page])
  end

	# Administrative activate action
	def update
		@user = User.find_by_login(params[:id])
    if @user.activate!
      flash[:notice] = "User activated."
    else
      flash[:error] = "There was a problem activating this user."
    end
    redirect_to :action => 'index'		
	end

  def destroy
    @user = User.find_by_login(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "User disabled."
    else
      flash[:error] = "There was a problem disabling this user."
    end
    redirect_to :action => 'index'
  end

  def enable
    @user = User.find_by_login(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "User enabled."
    else
      flash[:error] = "There was a problem enabling this user."
    end
    redirect_to :action => 'index'
  end

end

