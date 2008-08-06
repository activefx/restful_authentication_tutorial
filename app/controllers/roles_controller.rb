class RolesController < ApplicationController
  before_filter :login_required


  def index
    @user = User.find(params[:id])
		@roles = Role.find(:all, :order => :name)
	end


	def update
		params[:user][:role_ids] ||= []
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "User roles were successfully updated."
      redirect_to users_path
    else
      flash[:error] = 'There was a problem updating the roles for this user.'
      redirect_to users_path
    end
	end
end

