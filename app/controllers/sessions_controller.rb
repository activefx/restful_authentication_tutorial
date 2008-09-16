# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
	before_filter :login_prohibited, :only => [:new, :create]

  # render new.html.erb
  def new
		#	Display recaptcha only if the number of failed logins have 
		# exceeded the specified limit within a certain timeframe
		@bad_visitor = UserFailure.failure_check(request.remote_ip)
		respond_to do |format|
      format.html 
			format.js
    end
  end

  def create  
    logout_keeping_session!
		# Only verify recaptcha if the user has reached the failed login limit  
		@bad_visitor = UserFailure.failure_check(request.remote_ip)
		if @bad_visitor && !verify_recaptcha
			failed_login("The captcha was incorrect, please enter the words from the picture again.", 
											(params[:login] || params[:openid_identifier] || ''), params[:openid])
			return
		end
    if using_open_id?
      open_id_authentication(params[:openid_identifier])
    else
      password_authentication(params[:login], params[:password])
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected

  def password_authentication(name, password)
		SiteUser.authenticate(name, password) do |user, message, item_msg, item_path|
			(successful_login(user) and return) if user
			(flash[:error_item] = [item_msg, send(item_path)]) if item_path
			failed_login(message, name)
		end
	end

  # Track failed login attempts
  def note_failed_signin(message, login_name = nil)
		flash.now[:error] = message
		UserFailure.record_failure(request.remote_ip, request.env['HTTP_USER_AGENT'], "login", login_name)
  end

  def open_id_authentication(identity_url_params)
    # Pass optional :required and :optional keys to specify what sreg fields you want.
    # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.
    authenticate_with_open_id(identity_url_params, 
        :optional => [ :nickname, :email, :fullname],
				:invitation_token => params[:invitation_token],
				:remember_me => params[:remember_me],
				:requested => session[:return_to],
				:refered_from => session[:refered_from]) do |result, identity_url, registration|
			session[:return_to] = params[:requested]
			session[:refered_from] = params[:refered_from]
      case result.status
      when :missing
        failed_login("Sorry, the OpenID server couldn't be found.", identity_url, true)
      when :invalid
        failed_login("Sorry, but this does not appear to be a valid OpenID.", identity_url, true)
      when :canceled
        failed_login("OpenID verification was canceled.", identity_url, true)
      when :failed
        failed_login("Sorry, the OpenID verification failed.", identity_url, true)
      when :successful 
				OpenidUser.find_with_identity_url(identity_url) do |account, user, message, item_msg, item_path|
					if account	
						(successful_login(user) and return) if user
						flash[:error_item] = [item_msg, send(item_path)]
						failed_login(message, identity_url, true)
					else
						@user = OpenidUser.new(:invitation_token => params[:invitation_token])
						assign_registration_attributes!(registration, identity_url)
						if @user.save
	            redirect_to root_path
	    				flash[:notice] = "Thanks for signing up! "
							flash[:notice] += ((in_beta? && @user.emails_match?) ? "You can now log into 																		your account." : "We're sending you an email with your activation code.")
						else
							flash.now[:error] = "We need some additional details before we can create your account."
							render :template => "user/openid_accounts/new"
						end
					end
				end
      end
    end
  end

  # registration is a hash containing the valid sreg keys given above
  # use this to map them to fields of your user model
  def assign_registration_attributes!(registration, identity_url)
		@user.send(:identity_url=, identity_url)
    model_to_registration_mapping.each do |model_attribute, registration_attribute|
      unless registration[registration_attribute].blank?
        @user.send("#{model_attribute}=", registration[registration_attribute])
      end
    end
  end

  def model_to_registration_mapping
    { :login => 'nickname', :email => 'email', :name => 'fullname' }
  end

  private

  def successful_login(user)
    # Protects against session fixation attacks, causes request forgery
    # protection if user resubmits an earlier form using back
    # button. Uncomment if you understand the tradeoffs.
		#
		# reset_session has been uncommented in the restful_authentication_tutorial app,
		# which is not the default setting of the restful_authentication plugin
		# guides.rails.info/securing_rails_applications/security.html#_session_fixation_countermeasures
		#
		refered_from = session[:refered_from]
		return_to = session[:return_to]
    reset_session
		session[:refered_from] = refered_from 
		session[:return_to] = return_to
    self.current_user = user
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
    redirect_back_or_default('/')
    flash[:notice] = "Logged in successfully."
  end

  def failed_login(message, login_name, openid = nil) 	
		note_failed_signin(message, login_name)	   
    @login       			 = params[:login]
    @remember_me 			 = params[:remember_me]
		@openid_identifier = params[:openid_identifier] 
		@bad_visitor ||= UserFailure.failure_check(request.remote_ip)
		case
		when openid && params[:invitation_token]
			render :template => 'openid_sessions/index'
		when openid
			render :template => 'openid_sessions/new'
		else
			render :action => 'new'
		end
  end

end
