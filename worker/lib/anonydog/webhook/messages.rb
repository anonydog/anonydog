require 'mustache'

class Messages < Mustache; end
Messages.template_path = File.expand_path("../messages", __FILE__)
