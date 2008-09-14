class Invitation < ActiveRecord::Base
	belongs_to :sender, :class_name => 'User'
	has_one :recipient, :class_name => 'User'

	validates_presence_of 	:email
	validates_uniqueness_of :email, :message => '^This email address has already been submitted'
	validates_length_of     :email, :within => 6..100
  validates_format_of     :email, :with => Authentication.email_regex, 
																	:message => Authentication.bad_email_message

	validate :recipient_is_not_registered
	validate :sender_has_invitations, :if => :sender

	before_create :generate_token
	before_create :decrement_sender_count, :if => :sender

	attr_accessible :email

	def self.pending_users(page)
		paginate :all,
						 :per_page => 50, :page => page,
        		 :conditions => ['sent_at IS NULL'],
        		 :order => 'created_at ASC'
	end

	def self.users_for_mailing(limit)
		return nil if ((limit > 20) || (limit < 1))
		find :all,
				 :conditions => ['sent_at IS NULL'],
				 :order => 'created_at ASC',
				 :limit => limit
	end

	def self.send_to_pending_users(limit)
		if users = Invitation.users_for_mailing(limit)
			users.each do |user|
	  		UserMailer.deliver_invitation(user)
			end
			return true
		end
	end

	private

	def recipient_is_not_registered
	  errors.add :email, 'is already registered' if User.find_by_email(email)
	end

	def sender_has_invitations
	  unless sender.invitation_limit > 0
	    errors.add_to_base 'You have reached your limit of invitations to send.'
	  end
	end

	def generate_token
	  self.token = User.make_token
	end

	def decrement_sender_count
	  sender.decrement! :invitation_limit
	end

end
