class OpenidUser < User
	#model not working
	validates_presence_of   :identity_url 
	validates_uniqueness_of :identity_url

end
