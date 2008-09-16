class UserFailure < ActiveRecord::Base
	attr_accessible :remote_ip, :http_user_agent, :failure_type, :username

	# Looks for five failures within one hour from the same IP address
	def self.failure_check(remote_ip)
		find(:first, :conditions => 
			['remote_ip = ? and count > ? and updated_at >= ?', remote_ip, 5, 1.hour.ago])
	end

  def self.record_failure(remote_ip, http_user_agent, failure_type, username = nil)
		failure = find(:first, :conditions => ['remote_ip = ?', remote_ip],
													 :order => 'updated_at DESC')
		if (failure && failure.within_hour?)
			increment_count(failure, http_user_agent, failure_type, username)
		else
			new_user_failure(remote_ip, http_user_agent, failure_type, username)
		end
  end

	def self.new_user_failure(remote_ip, http_user_agent, failure_type, username)
		failure = new(:remote_ip => remote_ip, 
								 :http_user_agent => http_user_agent,
								 :failure_type => failure_type,
								 :username => username)
    failure.count += 1		
    failure.save	
	end

	def self.increment_count(failure, http_user_agent, failure_type, username)
		# Sets http_user_agent, failure_type, username of last failure only
		failure.http_user_agent = http_user_agent
		failure.failure_type = failure_type
		failure.username = username
		failure.count += 1		
    failure.save
	end

	#  Set limit for failed attempts within a certain period here
	def within_hour?
		updated_at >= 1.hour.ago		
	end

	# Set limit for failed attempts here
	def count_ok?
		count <= 5
	end
end
