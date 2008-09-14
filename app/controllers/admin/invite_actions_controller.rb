class Admin::InviteActionsController < ApplicationController
	before_filter :login_required
	require_role :admin

	# Show users waiting for an invitation code
	def index
		@users = Invitation.pending_users(params[:page])
	end

	# Add invitations to all users
	def create
		if User.add_to_invitation_limit(params[:add_invites].to_i)
      flash[:notice] = "Invitation limit updated."
      redirect_to admin_users_path
    else
			flash.now[:error] = "There was a problem updating the invitation limit."
      render :action => 'index'
		end
	end

end

