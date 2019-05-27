require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'active_support/inflector'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = route_params.merge(req.params)
    @@protected ||= false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise error if already_built_response?
    #@res.set_header('location', 'http://www.google.com')
    @res['location'] = 'http://www.google.com'
    @res.status = 302
    @already_built_response = true
    self.session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise error if already_built_response?
    res['Content-Type'] = content_type
    @res.write(content)
    @already_built_response = true
    self.session.store_session(@res)
  end

  def render(template_name)
    #gets the current file path we are in
    path = File.dirname(__FILE__)

    #gets the path before the current folder
    path = path.match(/^(.*[\\\/])/)[0]

    #gets the path to the correct view file
    template_path = File.join(path, "views/#{self.class.name.underscore}/#{template_name}.html.erb")
    
    # use File.read to read the template file
    content = File.read(template_path)

    # create a new ERB template from the content
    # evaluate the erb template, using binding to capture the controller's instance variables
    content = ERB.new(content).result(binding)

    # pass the result to #render_content with a 'content-type' of 'text.html'
    render_content(content, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    if protected? && req.request_method != "GET"
      check_authenticity_token
    end
    
    self.send(name)
    render(name) unless already_built_response?
  end

  #Phase XI
  def self.protect_from_forgery
    @@protected = true
  end

  def protected?
    @@protected
  end

  # Will provide your developer with a way to include the CSRF token in their form
  def form_authenticity_token
    @token ||= SecureRandom.urlsafe_base64
    res.set_cookie("authenticity_token", {value: @token, path: "/"})
    @token
  end

  # This method is what will actually be used to validate the auth token
  # It should be called from within #invoke_action.
  def check_authenticity_token
    cookie = req.cookies["authenticity_token"]
    unless cookie && cookie == params["authenticity_token"]
      raise "Invalid authenticity token"
    end
  end
end