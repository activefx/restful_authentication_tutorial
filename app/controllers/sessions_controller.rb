# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  # render new.html.erb
  def new
  end

  def create
    logout_keeping_session!
    if using_open_id?
			params[:login] = nil
      open_id_authentication(params[:openid_identifier])
    else
      password_authentication(params[:name], params[:password])
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end

  protected

  def password_authentication(name, password)
    user = User.authenticate(params[:login], params[:password])
    if user
			successful_login(user)
    else
			failed_login
    end
  end

  # Track failed login attempts
  def note_failed_signin(message)
    flash[:error] = message
    logger.warn "Failed login for '#{params[:login] || params[:openid_identifier]}' from #{request.remote_ip} at #{Time.now.utc}"
  end

  def open_id_authentication(identity_url)
    # Pass optional :required and :optional keys to specify what sreg fields you want.
    # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.
    authenticate_with_open_id(identity_url, 
        :required => [ :nickname, :email ],
        :optional => :fullname) do |result, identity_url, registration|
      case result.status
      when :missing
        failed_login "Sorry, the OpenID server couldn't be found"
      when :invalid
        failed_login "Sorry, but this does not appear to be a valid OpenID"
      when :canceled
        failed_login "OpenID verification was canceled"
      when :failed
        failed_login "Sorry, the OpenID verification failed"
      when :successful
				if user = User.find_by_identity_url(identity_url)
					successful_login(user)
				else
					@user = User.new
					assign_registration_attributes!(registration)
					if @user.save(false)
            redirect_back_or_default('/')
      			flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
					else
						failed_login "We were unable to create a new account for you from your OpenID profile." #+
              #@user.errors.full_messages.to_sentence					
					end
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
    flash[:notice] = "Logged in successfully"
  end

  def failed_login(message = "Couldn't log you in as '#{params[:login]}'")
    note_failed_signin(message)
    @login       = params[:login]
    @remember_me = params[:remember_me]
    render :action => 'new'
  end

end
