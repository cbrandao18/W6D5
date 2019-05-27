require 'erb'

class ShowExceptions
  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      app.call(env)
    rescue Exception => e
      render_exception(e)
    end
    
  end

  private
  def render_exception(e)
    path = File.dirname(__FILE__)
    template_path = File.join(path, "templates", "rescue.html.erb")
    template_body = File.read(template_path)
    template_content = ERB.new(template_body).result(binding)
    ["500", {'Content-type' => 'text/html'}, template_content]
  end

end
