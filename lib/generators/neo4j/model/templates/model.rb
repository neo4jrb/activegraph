class <%= class_name %> < <%= parent? ? options[:parent].classify : "Neo4j::Rails::Model" %>
<% attributes.each do |attribute| -%>
  property :<%= attribute.name %><%#, <%= attribute.type_class %> %>
<% end -%>

<%= timestamp_statements if timestamps? %>
end
