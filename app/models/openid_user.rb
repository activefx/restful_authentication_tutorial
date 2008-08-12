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
  attr_accessible :login, :email, :name, :identity_url, :role_ids
end
