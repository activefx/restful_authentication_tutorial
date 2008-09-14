module Authentication
  module UserAbstraction

		class NotActivated < StandardError; end
	  class NotEnabled < StandardError; end
		class NoActivationCode < StandardError; end
		class AlreadyActivated < StandardError; end
		class BlankEmail < StandardError; end
		class EmailNotFound < StandardError; end
		class OpenidAccount < StandardError; end
		class PasswordMismatch < StandardError; end

    # Stuff directives into including module
    def self.included( recipient )
      recipient.extend( ModelClassMethods )
      recipient.class_eval do
        include ModelInstanceMethods
				        
  				validates_presence_of     :login
  				validates_length_of       :login,    :within => 3..40
  				validates_uniqueness_of   :login
  				validates_format_of       :login,    :with => Authentication.login_regex, 
																							 :message => Authentication.bad_login_message

  				validates_format_of       :name,     :with => Authentication.name_regex,  
																							 :message => Authentication.bad_name_message, 
																							 :allow_nil => true
  				validates_length_of       :name,     :maximum => 100

  				validates_presence_of     :email
  				validates_length_of       :email,    :within => 6..100 #r@a.wk
  				validates_uniqueness_of   :email
  				validates_format_of       :email,    :with => Authentication.email_regex, 
																							 :message => Authentication.bad_email_message

					validates_presence_of 		:invitation_id, :message => 'is required', 
																										:on => :create, 
																										:if => :site_in_beta?
					validates_uniqueness_of 	:invitation_id, :on => :create, :if => :site_in_beta?

					validates_numericality_of :invitation_limit, 
																			:less_than_or_equal_to => APP_CONFIG['settings']['max_user_invite_limit'],
																			:on => :update

					before_create :set_invitation_limit
				  before_create :make_activation_code
 
					belongs_to :invitation
					has_and_belongs_to_many :roles
					has_many :sent_invitations, :class_name => 'Invitation', :foreign_key => 'sender_id'

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
				return nil if (login.blank? || password.blank?)
		    u = find :first, :conditions => ['login = ?', login], :include => :roles # need to get the salt
		    return nil unless (u && u.authenticated?(password))
				raise	NotActivated unless u.active?
				raise NotEnabled unless u.enabled?
				u
		  end

			def find_with_identity_url(identity_url)
		    u = self.find :first, :conditions => ['identity_url = ?', identity_url] 
				return nil if (identity_url.blank? || u.nil?) 
				raise	NotActivated unless u.active?
			  raise NotEnabled unless u.enabled?
				u
			end

			def send_new_activation_code(email)
				u = find :first, :conditions => ['email = ?', email]
				raise EmailNotFound if (email.blank? || u.nil?)
				return nil unless (u.send(:make_activation_code) && u.save(false))
				@lost_activation = true
			end	

			def find_with_activation_code(activation_code)
				raise NoActivationCode if activation_code.nil?
				u = find :first, :conditions => ['activation_code = ?', activation_code]
				return nil unless u
				u.active? ? (raise AlreadyActivated) : u
			end

			def find_with_password_reset_code(reset_code)
				u = find :first, :conditions => ['password_reset_code = ?', reset_code]
				raise StandardError if (reset_code.blank? || u.nil?)
				u
			end

		  def find_for_forget(email)
		    u = find :first, :conditions => ['email = ? and activated_at IS NOT NULL', email]
				return false if (email.blank? || u.nil? || (!u.identity_url.blank? && u.password.blank?))
				(u.forgot_password && u.save) ? true : false
		  end

			def add_to_invitation_limit(number)
				users = find :all, :conditions => ['enabled = ? and activated_at IS NOT NULL', true]
				users.each do |u|
					u.add_invites(number)
					u.save(false)
				end
			end

			def remove_all_invitations
				users = find :all
				users.each do |u|
					u.invitation_limit = 0
					u.save(false)
				end
			end
   
    end # class methods

    #
    # Instance Methods
    #
    module ModelInstanceMethods

  		def login=(value)
    		write_attribute :login, (value ? value.downcase : nil)
  		end

  		def email=(value)
    		write_attribute :email, (value ? value.downcase : nil)
  		end

			def invitation_token
			  invitation.token if invitation
			end

			def invitation_token=(token)
			  self.invitation = Invitation.find_by_token(token)
			end

      def to_param
        login
      end

		  def has_role?(role_in_question)
		    @_list ||= self.roles.collect(&:name)
				#Users with role "admin" can access any role protected resource
				#Comment the next line to disable this feature
		    return true if @_list.include?("admin")
		    (@_list.include?(role_in_question.to_s) )
		  end

			def change_password!(old_password, new_password, new_confirmation)
				raise OpenidAccount if (!self.identity_url.blank? && self.crypted_password.blank?)
				raise PasswordMismatch if (new_password != new_confirmation)
				return nil unless (!new_password.blank? && User.authenticate(self.login, old_password))
        self.password, self.password_confirmation = new_password, new_confirmation
				save
			end

		  # Activates the user in the database.
		  def activate!
		    @activated = true
		    self.activated_at = Time.now.utc
				#Leave activation code in place to determine if already activated.
		    #self.activation_code = nil
		    save(false)
		  end

		  def recently_activated?
		    @activated
		  end

		  def active?
				# If the activated_at date has not been set the user is not active
		    !activated_at.blank?
		  end

		  def forgot_password
		    self.make_password_reset_code
		    @forgotten_password = true
		  end

		  def reset_password!
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

		  def recently_created?
		    @created
		  end

			def site_in_beta?
				APP_CONFIG['settings']['in_beta']
			end

			def emails_match?
				return false if self.invitation.nil?
				self.email == self.invitation.email
			end

			def add_invites(number)
				self.invitation_limit || (self.invitation_limit = 0)
				if ((self.invitation_limit + number) > APP_CONFIG['settings']['max_user_invite_limit'])
					self.invitation_limit = APP_CONFIG['settings']['max_user_invite_limit']
				else
					self.invitation_limit += number
				end
			end
	
		  protected
		    
		  def make_activation_code
		    self.activation_code = self.class.make_token
				if site_in_beta? && emails_match?
					self.activated_at = Time.now
					@activated = true
				else
					@created = true
				end					
		  end

		  def make_password_reset_code
		    self.password_reset_code = self.class.make_token
		  end

			private

			def set_invitation_limit
				if site_in_beta?
  				self.invitation_limit = APP_CONFIG['settings']['new_user_invite_limit']
				end
			end

    end # instance methods

  end
end
