module We
  module Call
    module Middleware
      autoload :Client, 'we/call/middleware/client'
      autoload :Server, 'we/call/middleware/server'
    end
  end
end
