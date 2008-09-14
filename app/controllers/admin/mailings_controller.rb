class Admin::MailingsController < ApplicationController
	before_filter :login_required
	require_role :admin

	# Send invite emails
	def create
		if Invitation.send_to_pending_users(params[:limit].to_i)
			flash[:notice] = "Sending invitations."
			redirect_to admin_invites_path
		else
			flash[:error] = "There was a problem sending the invitations."
			redirect_to admin_invites_path
		end
	end

end
