class Admin::StatesController < ApplicationController
	before_filter :login_required
	require_role :admin

  def update
    @user = User.find_by_login(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "User enabled."
    else
      flash[:error] = "There was a problem enabling this user."
    end
    redirect_to admin_users_path
  end

  def destroy
    @user = User.find_by_login(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "User disabled."
    else
      flash[:error] = "There was a problem disabling this user."
    end
    redirect_to admin_users_path
  end

end
