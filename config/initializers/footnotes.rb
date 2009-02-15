#Change for your text editor for the footnotes plugin
#Ex. Textmate = "txmt://open?url=file://"
#See also http://josevalim.blogspot.com/2008/06/textmate-protocol-behavior-on-any.html

  if defined?(Footnotes)
    Footnotes::Filter.prefix = 'gedit://%s&line=%d&column=%d'
  end

#From the footnotes README file:
#	If you are not using Textmate as text editor, in your environment.rb or
#	in an initializer do:

#	  if defined?(Footnotes)
#	    Footnotes::Filter.prefix = 'txmt://open?url=file://%s&line=%d&column=%d'
#	  end

#	Where you are going to choose a prefix compatible with your text editor. The %s is
#	replaced by the name of the file, the first %d is replaced by the line number and
#	the second %d is replaced by the column. You can also enable this behaviour in other
#	editors following the steps in the link below:

#	  http://josevalim.blogspot.com/2008/06/textmate-protocol-behavior-on-any.html

#	By default, footnotes are appended at the end of the page with default stylesheet. If you want
#	to change their position, you can define a div with id "footnotes_holder" or define your own stylesheet
#	by turning footnotes stylesheet off:

#	  Footnotes::Filter.no_style = true

#	Another option is to allow multiple notes to be opened at the same time:

#	  Footnotes::Filter.multiple_notes = true

#	Finally, you can control which notes you want to show. The default are:

#	  Footnotes::Filter.notes = [:session, :cookies, :params, :filters, :routes, :env, :queries, :log, :general]


#	Creating your own notes
#	-----------------------

#	Create your notes to integrate with Footnotes is easy.

#	1. Create a Footnotes::Notes::YourExampleNote class

#	2. Implement the necessary methods (check abstract_note.rb file in lib/notes)

#	3. Append your example note in Footnotes::Filter.notes array (usually at the end of your environment file or in an initializer):

#	For example, to create a note that shows info about the user logged in your application you just have to do:

#	  module Footnotes
#	    module Notes
#	      class CurrentUserNote < AbstractNote
#	        # This method always receives a controller
#	        #
#	        def initialize(controller)
#	          @current_user = controller.instance_variable_get("@current_user")
#	        end

#	        # The name that will appear as legend in fieldsets
#	        #
#	        def legend
#	          "Current user: #{@current_user.name}"
#	        end

#	        # This Note is only valid if we actually found an user
#	        # If it's not valid, it won't be displayed
#	        #
#	        def valid?
#	          @current_user
#	        end

#	        # The fieldset content
#	        #
#	        def content
#	          escape(@current_user.inspect)
#	        end
#	      end
#	    end
#	  end

#	Then put in your environment:

#	  Footnotes::Filter.notes += [:current_user]
