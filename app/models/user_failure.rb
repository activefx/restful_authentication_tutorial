class UserFailure < ActiveRecord::Base
	
	def self.failure_check(remote_ip)
		find(:first, :conditions => 
			['remote_ip = ? and count > ? and updated_at >= ?', remote_ip, 5, 1.hour.ago])
	end

  def self.record_failure(remote_ip, http_user_agent, failure_type = nil)
		failure = find_by_remote_ip(remote_ip)
		if  (failure && failure.within_hour?)
			increment_count(failure, http_user_agent, failure_type)
		else
			new_user_failure(remote_ip, http_user_agent, failure_type)
		end
  end

	def self.new_user_failure(remote_ip, http_user_agent, failure_type)
		failure = new(:remote_ip => remote_ip, 
								 :http_user_agent => http_user_agent,
								 :failure_type => failure_type)
    failure.count += 1		
    failure.save	
	end

	def self.increment_count(failure, http_user_agent, failure_type)
		failure.http_user_agent = http_user_agent
		failure.failure_type = failure_type
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
