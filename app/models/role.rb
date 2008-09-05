class Role < ActiveRecord::Base
  #validates_presence_of     :name
  #validates_length_of       :name,    :within => 3..40
  #validates_uniqueness_of   :name,    :case_sensitive => false
  #validates_format_of       :name,    :with => /\w/, :message => "should be a word."

	attr_accessible nil  

	def to_xml(options = {})
		#Add attributes accessible by xml
  	#Ex. default_only = [:id, :name]
		default_only = []
  	options[:only] = (options[:only] || []) + default_only
  	super(options)
  end

end
