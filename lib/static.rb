class Static
  EXT_HASH = {
    ".txt" => "text/plain",
    ".jpg" => "image/jpeg",
    ".png" => "image/png",
    ".zip" => "application/zip"
  }

  attr_reader :app
  def initialize(app)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    if req.path =~ /public\// # can get file in public folder?
      res = file_get(env, req.path)
    else #continue to the app
      res = app.call(env)
    end
    res
  end

  def file_get(env, path)
    res = Rack::Response.new
    filename_path = path.match("public\/(.+)")[1]
    current_dir = File.dirname(__FILE__)
    prev_dir = current_dir.match(/^(.*[\\\/])/)[0]
    complete_path = File.join(prev_dir, path)

    if File.exist?(complete_path)
      ext = File.extname(filename_path)
      res["Content-type"] = EXT_HASH[ext]
      file = File.read(complete_path)
      res.write(file)
    else
      res.status = 404
      res.write("File not found")
    end
    res
  end

end
