module AuthenticatedTestHelper
  # Sets the current person in the session from the person fixtures.
  # Returns the person to allow @person = login_as(:quentin) construction.
  def login_as(user)
    if user.is_a?(User)
      id = user.id
    elsif user.is_a?(Symbol)
      user = users(user)
      id = user.id
    elsif user.nil?
      id = nil
    end
    # Stub out the controller if it's defined.
    # This means, e.g., that if a spec defines mocked-out photos for a person,
    # it current_person.photos will have the right assocation.
    if defined?(controller)
      controller.stub!(:current_user).and_return(user)
    else
      @request.session[:user_id] = id
    end
    user
  end

  def logout
    @request.session[:user_id] = nil
    if defined?(controller)
      controller.stub!(:current_user).and_return(:false)
    end
  end

  # Sets the current user in the session from the user fixtures.
#  def login_as(user)
#    @request.session[:user_id] = user ? users(user).id : nil
#  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'monkey') : nil
  end
  
  # rspec
#  def mock_user
#    user = mock_model(User, :id => 1,
#      :login  => 'user_name',
#      :name   => 'U. Surname',
#      :to_xml => "User-in-XML", :to_json => "User-in-JSON", 
#      :errors => [])
#    user
#  end  
end
