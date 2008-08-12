module Authentication
  module UserAbstraction

		class NotActivated < StandardError; end
	  class NotEnabled < StandardError; end
		class NoActivationCode < StandardError; end
		class AlreadyActivated < StandardError; end
		class BlankEmail < StandardError; end
		class EmailNotFound < StandardError; end

    # Stuff directives into including module
    def self.included( recipient )
      recipient.extend( ModelClassMethods )
      recipient.class_eval do
        include ModelInstanceMethods
				        
				  validates_presence_of     :login
				  validates_length_of       :login,    :within => 3..40
				  validates_uniqueness_of   :login,    :case_sensitive => false
				  validates_format_of       :login,    :with => RE_LOGIN_OK, :message => MSG_LOGIN_BAD

				  validates_format_of       :name,     :with => RE_NAME_OK,  :message => MSG_NAME_BAD, :allow_nil => true
				  validates_length_of       :name,     :maximum => 100

				  validates_presence_of     :email
				  validates_length_of       :email,    :within => 6..100 #r@a.wk
				  validates_uniqueness_of   :email,    :case_sensitive => false
				  validates_format_of       :email,    :with => RE_EMAIL_OK, :message => MSG_EMAIL_BAD

				  before_create :make_activation_code 

					has_and_belongs_to_many :roles


      end
    end # #included directives
    #
    # Class Methods
    #
    module ModelClassMethods

		  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
		  #
		  # uff.  this is really an authorization, not authentication routine.  
		  # We really need a Dispatch Chain here or something.
		  # This will also let us return a human error message.
		  #
		  def authenticate(login, password)
		    u = find :first, :conditions => ['login = ?', login] # need to get the salt
		    #u && u.authenticated?(password) ? u : nil
		    if (u && u.authenticated?(password))
				  raise	NotActivated if u.activated_at.blank?
					raise NotEnabled if !u.enabled?
					u
				else
					nil
				end
		  end

			def send_new_code(email)
				raise BlankEmail if email.blank?
				u = find :first, :conditions => ['email = ?', email]
				raise EmailNotFound if u.nil?
				if u.send(:make_activation_code) && u.save(false)
					@lost_activation = true
				else
					false
				end
			end	

			def find_with_activation_code(activation_code)
				raise NoActivationCode if activation_code.nil?
				u = find :first, :conditions => ['activation_code = ?', activation_code]
				if u
					raise AlreadyActivated if !u.activated_at.blank?
					u
				else
					nil
				end
			end

		  def find_for_forget(email)
		    find :first, :conditions => ['email = ? and activated_at IS NOT NULL', email]
		  end
   
    end # class methods

    #
    # Instance Methods
    #
    module ModelInstanceMethods
      
		  def has_role?(role_in_question)
		    @_list ||= self.roles.collect(&:name)
		    return true if @_list.include?("admin")
		    (@_list.include?(role_in_question.to_s) )
		  end

		  # Activates the user in the database.
		  def activate!
		    self.activated_at = Time.now.utc
				#Leave activation code in place to determine if already activated.
		    #self.activation_code = nil
		    save(false)
		    @activated = true
		  end

		  def recently_activated?
		    @activated
		  end

		  def active?
		    # the existence of an activation code means they have not activated yet
		    activation_code.nil?
		  end

		  def forgot_password
		    self.make_password_reset_code
		    @forgotten_password = true
		  end

		  def reset_password
		    # First update the password_reset_code before setting the
		    # reset_password flag to avoid duplicate email notifications.
		    update_attribute(:password_reset_code, nil)
		    @reset_password = true
		  end

		  #used in user_observer
		  def recently_forgot_password?
		    @forgotten_password
		  end

			def lost_activation_code?
				@lost_activation
			end

		  def recently_reset_password?
		    @reset_password
		  end

		  protected
		    
		  def make_activation_code
		    self.activation_code = self.class.make_token
		  end

		  def make_password_reset_code
		    self.password_reset_code = self.class.make_token
		  end

    end # instance methods

  end
end
