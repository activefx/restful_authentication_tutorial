class Admin::InvitesController < ApplicationController
	before_filter :login_required
	require_role :admin

	def index
	end

	# Remove invitations from all current users
	def create
		if params[:remove_invites]
			User.remove_all_invitations
      flash[:notice] = "Invitation limit updated."
      redirect_to admin_users_path
    else
			flash.now[:error] = "There was a problem updating the invitation limit."
      render :action => 'index'
		end
	end

	# Edit a user's invitation limit
	def edit
		@user = User.find_by_login(params[:id])
	end

	def update
    @user = User.find_by_login(params[:id])
		@user.invitation_limit = params[:user][:invitation_limit]
    if @user.save
      flash[:notice] = "Invitation limit updated."
      redirect_to :action => 'edit', :id => params[:id]
    else
			flash.now[:error] = "There was a problem updating the invitation limit."
      render :action => 'edit'
    end
	end

end
