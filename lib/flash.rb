require 'json'

class Flash

  attr_reader :now

  def initialize(req)
    cookie_flash = req.cookies["_rails_lite_app_flash"]
    if cookie_flash
      @now = JSON.parse(cookie_flash)
    else
      @now = {}
    end
    @next = {}
  end

  def [](key)
    if @now[key]
      return @now[key.to_s]
    else
      return @next[key.to_s]
    end
  end

  def []=(key, val)
    #why aren't we keying into @now?
    # adding a reader to a hash is sufficient in order to modify it
    @next[key.to_s] = val
  end

  def store_flash(res)
    res.set_cookie("_rails_lite_app_flash", {path:'/', value: @next.to_json}) #store @next?
  end
end
