class Admin::RolesController < ApplicationController
  before_filter :login_required
	require_role :admin

  def index
    @user = User.find_by_login(params[:user_id], :include => :roles)
		@roles = Role.find(:all, :order => :name)
	end

	def update
		params[:user][:role_ids] ||= []
    @user = User.find_by_login(params[:user_id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "User roles were successfully updated."
      redirect_to admin_user_roles_path(@user)
    else
      flash[:error] = 'There was a problem updating the roles for this user.'
      redirect_to admin_user_roles_path(@user)
    end
	end
end

