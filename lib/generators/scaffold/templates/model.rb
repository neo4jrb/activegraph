class <%=class_name%> < Neo4j::Model
    property :<%= (attributes.collect {|attribute| attribute.name.to_sym})*',:' %>
end