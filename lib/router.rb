class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    req.path =~ @pattern && req.request_method.downcase == @http_method.to_s
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    # get a MatchData object using the route's @pattern, 
    # and then build a route_params hash from it.
    regex = Regexp.new(@pattern)
    match_data_obj = regex.match(req.path)
    # match_data_obj = req.path.match(@pattern) 
    keys = match_data_obj.names
    values = match_data_obj.captures
    match_hash = Hash[keys.zip(values)]
    #instantiates an instance of the controller class
    controller = @controller_class.new(req, res, match_hash)
    #calls invoke_action
    controller.invoke_action(action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.find {|route| route.matches?(req)}
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    route = match(req)
    if route
      route.run(req, res)
    else
      #throw 404
      res.status = 404
    end
  end
end
