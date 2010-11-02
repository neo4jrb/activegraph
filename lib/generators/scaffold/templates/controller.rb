class <%=class_name.pluralize%>Controller < NeoController
  # GET /<%=plural_name%>
  # GET /<%=plural_name%>.xml
  def index
    @<%=plural_name%> = <%=class_name%>.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @<%=plural_name%> }
    end
  end

  # GET /<%=plural_name%>/1
  # GET /<%=plural_name%>/1.xml
  def show
    @<%=singular_name%> = <%=class_name%>.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @<%=singular_name%> }
    end
  end

  # GET /<%=plural_name%>/new
  # GET /<%=plural_name%>/new.xml
  def new
    @<%=singular_name%> = <%=class_name%>.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @<%=singular_name%> }
    end
  end

  # GET /<%=plural_name%>/1/edit
  def edit
    @<%=singular_name%> = <%=class_name%>.find(params[:id])
  end

  # POST /<%=plural_name%>
  # POST /<%=plural_name%>.xml
  def create
    @<%=singular_name%> = <%=class_name%>.new(params[:<%=singular_name%>])

    respond_to do |format|
      if @<%=singular_name%>.save
        format.html { redirect_to(@<%=singular_name%>, :notice => '<%=class_name%> was successfully created.') }
        format.xml  { render :xml => @<%=singular_name%>, :status => :created, :<%=singular_name%> => @<%=singular_name%> }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @<%=singular_name%>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /<%=plural_name%>/1
  # PUT /<%=plural_name%>/1.xml
  def update
    @<%=singular_name%> = <%=class_name%>.find(params[:id])

    respond_to do |format|
      if @<%=singular_name%>.update_attributes(params[:<%=singular_name%>])
        format.html { redirect_to(@<%=singular_name%>, :notice => '<%=class_name%> was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @<%=singular_name%>.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /<%=plural_name%>/1
  # DELETE /<%=plural_name%>/1.xml
  def destroy
    @<%=singular_name%> = <%=class_name%>.find(params[:id])
    @<%=singular_name%>.destroy

    respond_to do |format|
      format.html { redirect_to(<%=plural_name%>_url) }
      format.xml  { head :ok }
    end
  end
end