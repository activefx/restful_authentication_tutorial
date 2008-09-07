class Admin::ControlsController < ApplicationController
  before_filter :login_required
	require_role :admin

  def index
    @users = User.count
		@exceptions = LoggedException.count
	end
end
