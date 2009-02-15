require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PeopleController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "people", :action => "index").should == "/people"
    end
  
    it "should map #new" do
      route_for(:controller => "people", :action => "new").should == "/people/new"
    end
  
    it "should map #show" do
      route_for(:controller => "people", :action => "show", :id => 1).should == "/people/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "people", :action => "edit", :id => 1).should == "/people/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "people", :action => "update", :id => 1).should == "/people/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "people", :action => "destroy", :id => 1).should == "/people/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/people").should == {:controller => "people", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/people/new").should == {:controller => "people", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/people").should == {:controller => "people", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/people/1").should == {:controller => "people", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/people/1/edit").should == {:controller => "people", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/people/1").should == {:controller => "people", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/people/1").should == {:controller => "people", :action => "destroy", :id => "1"}
    end
  end
end
