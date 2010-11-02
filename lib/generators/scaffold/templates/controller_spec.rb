require 'spec_helper'

describe <%=class_name.pluralize%>Controller do

  def mock_<%=singular_name%>(stubs={})
    @mock_<%=singular_name%> ||= mock_model(<%=class_name%>, stubs).as_null_object
  end

  describe "GET index" do
    it "assigns all <%=plural_name%> as @<%=plural_name%>" do
      <%=class_name%>.stub(:all) { [mock_<%=singular_name%>] }
      get :index
      assigns(:<%=plural_name%>).should eq([mock_<%=singular_name%>])
    end
  end

  describe "GET show" do
    it "assigns the requested <%=singular_name%> as @<%=singular_name%>" do
      <%=class_name%>.stub(:find).with("37") { mock_<%=singular_name%> }
      get :show, :id => "37"
      assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
    end
  end

  describe "GET new" do
    it "assigns a new <%=singular_name%> as @<%=singular_name%>" do
      <%=class_name%>.stub(:new) { mock_<%=singular_name%> }
      get :new
      assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
    end
  end

  describe "GET edit" do
    it "assigns the requested <%=singular_name%> as @<%=singular_name%>" do
      <%=class_name%>.stub(:find).with("37") { mock_<%=singular_name%> }
      get :edit, :id => "37"
      assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created <%=singular_name%> as @<%=singular_name%>" do
        <%=class_name%>.stub(:new).with({'these' => 'params'}) { mock_<%=singular_name%>(:save => true) }
        post :create, :<%=singular_name%> => {'these' => 'params'}
        assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
      end

      it "redirects to the created <%=singular_name%>" do
        <%=class_name%>.stub(:new) { mock_<%=singular_name%>(:save => true) }
        post :create, :<%=singular_name%> => {}
        response.should redirect_to(<%=singular_name%>_url(mock_<%=singular_name%>))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved <%=singular_name%> as @<%=singular_name%>" do
        <%=class_name%>.stub(:new).with({'these' => 'params'}) { mock_<%=singular_name%>(:save => false) }
        post :create, :<%=singular_name%> => {'these' => 'params'}
        assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
      end

      it "re-renders the 'new' template" do
        <%=class_name%>.stub(:new) { mock_<%=singular_name%>(:save => false) }
        post :create, :<%=singular_name%> => {}
        response.should render_template("new")
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested <%=singular_name%>" do
        <%=class_name%>.should_receive(:find).with("37") { mock_<%=singular_name%> }
        mock_<%=singular_name%>.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :<%=singular_name%> => {'these' => 'params'}
      end

      it "assigns the requested <%=singular_name%> as @<%=singular_name%>" do
        <%=class_name%>.stub(:find) { mock_<%=singular_name%>(:update_attributes => true) }
        put :update, :id => "1"
        assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
      end

      it "redirects to the <%=singular_name%>" do
        <%=class_name%>.stub(:find) { mock_<%=singular_name%>(:update_attributes => true) }
        put :update, :id => "1"
        response.should redirect_to(<%=singular_name%>_url(mock_<%=singular_name%>))
      end
    end

    describe "with invalid params" do
      it "assigns the <%=singular_name%> as @<%=singular_name%>" do
        <%=class_name%>.stub(:find) { mock_<%=singular_name%>(:update_attributes => false) }
        put :update, :id => "1"
        assigns(:<%=singular_name%>).should be(mock_<%=singular_name%>)
      end

      it "re-renders the 'edit' template" do
        <%=class_name%>.stub(:find) { mock_<%=singular_name%>(:update_attributes => false) }
        put :update, :id => "1"
        response.should render_template("edit")
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested <%=singular_name%>" do
      <%=class_name%>.should_receive(:find).with("37") { mock_<%=singular_name%> }
      mock_<%=singular_name%>.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the <%=plural_name%> list" do
      <%=class_name%>.stub(:find) { mock_<%=singular_name%> }
      delete :destroy, :id => "1"
      response.should redirect_to(<%=plural_name%>_url)
    end
  end

end