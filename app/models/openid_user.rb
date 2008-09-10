class OpenidUser < User
	validates_presence_of   :identity_url 
	validates_uniqueness_of :identity_url

end
