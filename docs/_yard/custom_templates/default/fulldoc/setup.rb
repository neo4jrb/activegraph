require 'fileutils'

def render_node(object, ancestry = [])
  path = ancestry.map(&:name).map(&:to_s).join('/')

  @module = object
  @path = path

  FileUtils.mkdir_p(path) unless path.empty?
  asset File.join(path, "#{object.name}.rst"), erb(:module)

  if object.respond_to?(:children)
    object.children.each do |child|
      render_node(child, ancestry + [object]) if child.is_a?(YARD::CodeObjects::NamespaceObject)
    end
  end
end

