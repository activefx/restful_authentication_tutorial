module Authentication
  module UserAbstraction

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
																			:on => :update, :allow_nil => true, :if => :site_in_beta?

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

			def send_new_activation_code(email = nil, &block) #yield error, message, path
				u = find :first, :conditions => ['email = ?', email]
				case 
				when (email.blank? || u.nil?)
					yield :error, "Could not find a user with that email address.", "resend_activation_path"
				when (u.send(:make_activation_code) && u.save(false))
					@lost_activation = true
					yield :notice, "A new activation code has been sent to your email address.", "root_path"
				else
					yield :error, "There was a problem resending your activation code, please try again or %s.", 							"resend_activation_path"
				end
			end

			def find_with_activation_code(activation_code = nil, &block) #yield error, message, path
				u = find :first, :conditions => ['activation_code = ?', activation_code]				
				case
				when activation_code.nil?
					yield :error, "The activation code was missing, please follow the URL from your email.", "root_path"
				when u.nil?
					yield :error, "We couldn't find a user with that activation code, please check your email and try 						again, or %s.", "root_path"
				when u.active?
					yield :notice, "Your account has already been activated. You can log in below", "login_path"
				when u
					u.activate!
					path = ((u.user_type == "OpenidUser") ? "login_with_openid_path" : "login_path")
					yield :notice, "Signup complete! Please sign in to continue.", path
				end
			end

			# find_each method from pseudo_cursors
			def add_to_invitation_limit(number)
				find_each(:conditions => ['enabled = ? and activated_at IS NOT NULL', true]) do |u|
					u.add_invites(number)
					u.save(false)
				end
			end

			# find_each method from pseudo_cursors
			def remove_all_invitations
				find_each do |u|
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
				errors.add_to_base("OpenID users cannot change their password.") and
					return false if (!self.identity_url.blank? && self.crypted_password.blank?)
				errors.add_to_base("New password does not match the password confirmation.") and
					return false if (new_password != new_confirmation)
				errors.add_to_base("New password cannot be blank.") and
					return false if new_password.blank? 
				errors.add_to_base("You password was not changed, your old password is incorrect.") and
					return false unless self.authenticated?(old_password) 
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
				return false unless invitation
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
