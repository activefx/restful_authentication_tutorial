class User::InvitationsController < ApplicationController

	def new
	  @invitation = Invitation.new
	end

	def create
	  @invitation = Invitation.new(params[:invitation])
	  @invitation.sender = current_user
	  if @invitation.save
	    if logged_in?
	      UserMailer.deliver_invitation(@invitation)
	      flash[:notice] = "Thank you, invitation sent."
	      redirect_to root_path
	    else
	      flash[:notice] = "Thank you, we will notify you when an invitation becomes available."
	      redirect_to root_path
	    end
	  else
	    render :action => 'new'
	  end
	end

end

