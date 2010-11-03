class <%= class_name %> < <%= parent? ? options[:parent].classify : "Neo4j::Rails::Model" %>
<% attributes.each do |attribute| -%>
	property :<%= attribute.name %><%= ", :type => #{attribute.type_class}" unless attribute.type_class == "String" %>
<% end -%>

<%= timestamp_statements if timestamps? -%>
end
