require 'reloader/sse'

class BrowserController < ApplicationController
  include ActionController::Live

  def index
    # SSE expects the 'text/event-stream' content type
    response.headers['Content-Type'] = 'text/event-stream'

    sse = Reloader::SSE.new(response.stream)
    begin
      # Send a message on the "refresh" channel on every update
      handler = Proc.new { sse.write({ :directory => 'directory'}, :event => 'refresh') }
      dir_name = File.join(Rails.root, 'app', 'assets')
      notifier = INotify::Notifier.new

      notifier.watch(dir_name, :modify, :recursive, &handler)
      loop do
        notifier.process
        notifier.watch(dir_name, :modify, :recursive, &handler)
      end
    rescue IOError
      # When the client disconnects, we'll get an IOError on write
    ensure
      sse.close
    end
  end
end
