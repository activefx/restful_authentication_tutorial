class Admin::RolesController < ApplicationController
  before_filter :login_required
	require_role :admin

  def index
    @user = User.find_by_login(params[:user_id], :include => :roles)
		@roles = Role.find(:all, :order => :name)
	end

	def update
		@user = User.find_by_login(params[:user_id])
		@roles = (Role.find(params[:user][:role_ids]) if params[:user][:role_ids])
		@user.roles = (@roles || [])
		if @user.save
      flash[:notice] = "User roles were successfully updated."
      redirect_to admin_user_roles_path(@user)
		else
      flash[:error] = 'There was a problem updating the roles for this user.'
      redirect_to admin_user_roles_path(@user)
		end
	end

end

