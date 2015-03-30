require 'fileutils'

def init
  root_object = @objects.find(&:root?)

  root_object.children.each do |object|
    render_node(object)
  end

  @toc = root_object.children.map(&:name)

  asset 'index.rst', erb(:index)
end

def render_node(object, ancestry = [])
  path = ancestry.map(&:name).map(&:to_s).join('/')

  @module = object
  @path = path

  FileUtils.mkdir_p(path) unless path.empty?
  asset File.join(path, "#{object.name}.rst"), erb(:module)

  return if !object.respond_to?(:children)

  object.children.each do |child|
    render_node(child, ancestry + [object]) if child.is_a?(YARD::CodeObjects::NamespaceObject)
  end
end

def asset(path, content)
  return if !options.serializer

  log.capture("Generating asset #{path}") do
    options.serializer.serialize(path, content)
  end
end
