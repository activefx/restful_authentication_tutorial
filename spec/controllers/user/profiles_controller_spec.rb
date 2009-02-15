require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe User::ProfilesController do
  fixtures :users

  def mock_user(stubs={})
    @mock_user ||= mock_model(SiteUser, stubs)
  end

  describe " responding to GET show" do

		def do_get
			@logged_in_user = login_as(:quentin)
      get :show, :id => @logged_in_user.login
		end

	  it "should restrict access to logged in users" do
	    get :show, :id => "1"
	    response.should redirect_to(login_path)
	  end

    it "should assign the logged in user as @user" do
			do_get
      assigns[:user].should equal(@logged_in_user)
    end

    it "should be successful" do
			do_get
      response.should be_success
    end			

    it "should render show template" do
			do_get
      response.should render_template('show')
    end	
   
  end #show

	describe " responding to GET new" do

	  it "should prohibit access for logged in users" do
			login_as(:quentin)
	    get :new
	    response.should redirect_to(root_path)
	  end

    it "should be successful" do
			get :new
      response.should be_success
    end	

    it "should render new template" do
			get :new
      response.should render_template('new')
    end	

	  it "should create a new instance of SiteUser" do
			@user = mock_model(SiteUser)
			SiteUser.stub!(:new).and_return(@user)
	    SiteUser.should_receive(:new).and_return(@user)
	    get :new
	  end

    it "should assign the new user as @user" do
			@user = mock_model(SiteUser)
			SiteUser.stub!(:new).and_return(@user)
	    get :new
      assigns[:user].should equal(@user)
    end

		describe " when site is in beta" do

			it "should assign the new user as @user with the invitation_token when included" do
				if APP_CONFIG['settings']['in_beta'] == true
					@user = mock_model(SiteUser, :invitation_token => 'invitation_code')
					SiteUser.stub!(:new).and_return(@user)
					get :new, :invitation_token => 'invitation_code'					
					assigns[:user].should equal(@user)
					assigns(:user).invitation_token.should_not be_nil
				end
			end

		end

	end #new

  describe "responding to POST create" do

	  it "should prohibit access for logged in users" do
			login_as(:quentin)
	    post :create
	    response.should redirect_to(root_path)
	  end

    describe "with valid params" do
		
			before do
				@user = mock_model(SiteUser, :save => true)
				SiteUser.stub!(:new).and_return(@user)
				@params = { :login => 'quire', :email => 'quire@example.com',
      		:password => 'quire69', :password_confirmation => 'quire69', :errors => {} }
			end
      
      it "should create a new person with valid params" do
        SiteUser.should_receive(:new).with(@params).and_return(mock_user(:save => true))
        post :create, :user => @params
				response.should be_success
		    flash[:notice].should_not be_nil
      end

      it "should redirect to the created person" do
        SiteUser.should_receive(:new).with(@params).and_return(mock_user(:save => true, :errors => []))
        post :create, :user => @params
        assigns(:user).should_receive(:save)
				#assigns[:user].errors.should_receive(:empty?).and_return(false)
        response.should redirect_to('/')
      end
      
    end
#          it "should expose a newly created person as @person" do
#        Person.should_receive(:new).with({'these' => 'params'}).and_return(mock_person(:save => true))
#        post :create, :person => {:these => 'params'}
#        assigns(:person).should equal(mock_person)
#      end

#      it "should redirect to the created person" do
#        Person.stub!(:new).and_return(mock_person(:save => true))
#        post :create, :person => {}
#        response.should redirect_to(person_url(mock_person))
#      end
#    describe "with invalid params" do

#      it "should expose a newly created but unsaved person as @person" do
#        Person.stub!(:new).with({'these' => 'params'}).and_return(mock_person(:save => false))
#        post :create, :person => {:these => 'params'}
#        assigns(:person).should equal(mock_person)
#      end

#      it "should re-render the 'new' template" do
#        Person.stub!(:new).and_return(mock_person(:save => false))
#        post :create, :person => {}
#        response.should render_template('new')
#      end
#      
#    end
    


	end
#  it 'allows signup' do
#    lambda do
#      create_user
#      response.should be_success
#    end.should change(User, :count).by(1)
#  end  

#  it 'creates an activation code when signing up a new user' do
#    create_user
#    assigns(:user).reload
#    assigns(:user).activated_at.should_not be_nil
#  end

#  it 'requires login on signup' do
#    lambda do
#      create_user(:login => nil)
#      assigns[:user].errors.on(:login).should_not be_nil
#      response.should be_success
#    end.should_not change(User, :count)
#  end
#  
#  it 'requires password on signup' do
#    lambda do
#      create_user(:password => nil)
#      assigns[:user].errors.on(:password).should_not be_nil
#      response.should be_success
#    end.should_not change(User, :count)
#  end
#  
#  it 'requires password confirmation on signup' do
#    lambda do
#      create_user(:password_confirmation => nil)
#      assigns[:user].errors.on(:password_confirmation).should_not be_nil
#      response.should be_success
#    end.should_not change(User, :count)
#  end

#  it 'requires email on signup' do
#    lambda do
#      create_user(:email => nil)
#      assigns[:user].errors.on(:email).should_not be_nil
#      response.should be_success
#    end.should_not change(User, :count)
#  end
  
#  
#  it 'activates user' do
#    User.authenticate('aaron', 'monkey').should be_nil
#    get :activate, :activation_code => users(:aaron).activation_code
#    response.should redirect_to('/login')
#    flash[:notice].should_not be_nil
#    flash[:error ].should     be_nil
#    User.authenticate('aaron', 'monkey').should == users(:aaron)
#  end
#  
#  it 'does not activate user without key' do
#    get :activate
#    flash[:notice].should     be_nil
#    flash[:error ].should_not be_nil
#  end
#  
#  it 'does not activate user with blank key' do
#    get :activate, :activation_code => ''
#    flash[:notice].should     be_nil
#    flash[:error ].should_not be_nil
#  end
#  
#  it 'does not activate user with bogus key' do
#    get :activate, :activation_code => 'i_haxxor_joo'
#    flash[:notice].should     be_nil
#    flash[:error ].should_not be_nil
#  end
  
  def create_user(options = {})
    post :create, :user => { :user_type => 'SiteUser', :login => 'quire', :email => 'quire@example.com',
      :password => 'quire69', :password_confirmation => 'quire69' }.merge(options)
  end
end


