class FourOhFoursController < ApplicationController
  def index
    FourOhFour.add_request(request.url,
                           request.env['HTTP_REFERER'] || '')
    respond_to do |format|
      format.html { render :file => "#{RAILS_ROOT}/public/404.html" ,
                           :status => "404 Not Found" }
      format.all { render :nothing => true,
                           :status => "404 Not Found" }
    end
  end
end

