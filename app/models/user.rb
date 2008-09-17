require 'digest/sha1'

class User < ActiveRecord::Base  
	include Authentication
  include Authentication::ByCookieToken
	include Authentication::UserAbstraction

	set_inheritance_column :user_type
	validates_presence_of  :user_type
  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
	# Add identity_url if you want users to be able to update their OpenID identity
  attr_accessible :login, :email, :name, :password, :password_confirmation, :invitation_token

	def self.member_list(page)
		paginate :all,
						 :per_page => 50, :page => page,
        		 :conditions => ['enabled = ? and activated_at IS NOT NULL', true],
        		 :order => 'login'
	end

	def self.administrative_member_list(page)
		paginate :all,
						 :per_page => 50, :page => page,
        		 :order => 'login'
	end

	def to_xml(options = {})
		#Add attributes accessible by xml
  	#Ex. default_only = [:id, :login, :name]
		default_only = []
  	options[:only] = (options[:only] || []) + default_only
  	super(options)
  end

end
