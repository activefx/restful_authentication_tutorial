class RolesController < ApplicationController
  before_filter :login_required
	require_role :admin

  def index
    @user = User.find(params[:user_id])
		@roles = Role.find(:all, :order => :name)
	end


	def update
		params[:user][:role_ids] ||= []
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "User roles were successfully updated."
      redirect_to user_roles_path(@user)
    else
      flash[:error] = 'There was a problem updating the roles for this user.'
      redirect_to user_roles_path(@user)
    end
	end
end

