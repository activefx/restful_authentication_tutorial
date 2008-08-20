require 'digest/sha1'

class OpenidUser < ActiveRecord::Base
	set_table_name "users"

  include Authentication
  include Authentication::ByCookieToken
	include Authentication::UserAbstraction

	validates_presence_of   :identity_url 
	validates_uniqueness_of :identity_url

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name

	def to_xml(options = {})
		#Add attributes accessible by xml
  	#Ex. default_only = [:id, :login, :name]
		default_only = []
  	options[:only] = (options[:only] || []) + default_only
  	super(options)
  end
end
