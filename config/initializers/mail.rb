# Email settings
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => APP_CONFIG['mail']['address'],
  :port => APP_CONFIG['mail']['port'],
  :domain => APP_CONFIG['mail']['domain'],
  :authentication => APP_CONFIG['mail']['authentication'],
  :user_name => APP_CONFIG['mail']['user_name'],
  :password => APP_CONFIG['mail']['password']  
}


