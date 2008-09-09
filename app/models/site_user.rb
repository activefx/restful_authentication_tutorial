class SiteUser < User
	include Authentication::ByPassword

end
