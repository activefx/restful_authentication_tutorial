# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # render new.html.erb
  def new
  end

  def create
    logout_keeping_session!
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
    begin
			user = User.authenticate(name, password)
      if user
			  successful_login(user)
      else
			  failed_login("Could not log you in as '#{name}', your username or password is incorrect.", name)
      end
		rescue Authentication::UserAbstraction::NotActivated
			failed_login("Your account has not been activated.", name)
		rescue Authentication::UserAbstraction::NotEnabled
			#replace with your site's contact form
			flash[:error_item] = ["contact the administrator", root_path]
			failed_login("Your account has been disabled, please %s.", name)
		end
  end

  # Track failed login attempts
  def note_failed_signin(message, login_name)
    flash[:error] = message		
    logger.warn "Failed login for '#{login_name}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def open_id_authentication(identity_url_params)
    # Pass optional :required and :optional keys to specify what sreg fields you want.
    # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.
    authenticate_with_open_id(identity_url_params, 
        :optional => [ :nickname, :email, :fullname]) do |result, identity_url, registration|
      case result.status
      when :missing
        failed_login("Sorry, the OpenID server couldn't be found.", identity_url)
      when :invalid
        failed_login("Sorry, but this does not appear to be a valid OpenID.", identity_url)
      when :canceled
        failed_login("OpenID verification was canceled.", identity_url)
      when :failed
        failed_login("Sorry, the OpenID verification failed.", identity_url)
      when :successful
				begin
					if user = User.find_with_identity_url(identity_url)
						successful_login(user)
					else
						@user = OpenidUser.new
						assign_registration_attributes!(registration)
						@user.identity_url = identity_url
						if @user.save
	            redirect_back_or_default('/')
	      			flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
						else
							flash[:error] = "We need some additional details before we can create your account."
							session[:identity_url] = identity_url
							render :template => "openid_users/new"
						end
					end
				rescue Authentication::UserAbstraction::NotActivated
					failed_login ("Your account has not been activated.", identity_url)
				rescue Authentication::UserAbstraction::NotEnabled
					#replace with your site's contact form
					flash[:error_item] = ["contact the administrator", root_path]
					failed_login("Your account has been disabled, please %s.", identity_url)
				end
      end
    end
  end
      
  # registration is a hash containing the valid sreg keys given above
  # use this to map them to fields of your user model
  def assign_registration_attributes!(registration)
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
    # reset_session
    self.current_user = user
    new_cookie_flag = (params[:remember_me] == "1")
    handle_remember_cookie! new_cookie_flag
    redirect_back_or_default('/')
    flash[:notice] = "Logged in successfully."
  end

  def failed_login(message, login_name)
    note_failed_signin(message, login_name)
    @login       = params[:login]
    @remember_me = params[:remember_me]
    render :action => 'new'
  end

end
