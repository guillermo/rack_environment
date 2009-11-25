class RackEnvironment
  
  def initialize(app)
    @app = app
    @environments = {}
    @changes = lambda {}
    yield self
  end
  
  def call(env)
    @env = env
    dup._call(env)
  end
  
  def _call(env)
    @status, @headers, @response = @app.call(env)
      @@environment ||= detect_env
      if @@environment && modificable?(@response)
        @@changes ||= @changes.call(@@environment.first)
        @response.body = append_string_to_body(@response.body,@@changes)
        @headers["Content-Length"] = @response.body.size.to_s
      end
  rescue => e
    $stderr << e.inspect+"\n"
    $stderr << e.backtrace.join("\n")+"\n"
  ensure
    return [@status, @headers, @response]
  end
  
  
  def define_environment(name, proc)
    @environments[name] = proc
  end
  
  def append_to_body(proc)
    @changes = proc
  end
  
  def server_name
    @env['SERVER_NAME']
  end
    
  private
  
  def modificable?(response)
    response.content_type == 'text/html' &&
    response.body.kind_of?(String)
  rescue
    nil
  end
  
  def append_string_to_body(html,msg)
    html.gsub(/<body[^>]*>/i) { "#{$&}\n#{msg}" }
  end
  
  # Return an array:
  #  [:dev, &proc ]
  def detect_env
    @environments.find{|env_name,proc|
      instance_eval(&proc)
    }    
  end
  
end
