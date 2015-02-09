require 'net/http'
require 'cgi'

module Akismet

  # A Ruby client for the Akismet API.
  #
  # @example
  #
  #   # Verify an API key
  #   #
  #
  #   Akismet::Client.new( 'apikey123', 'http://jonahb.com' ).verify_key
  #
  # @example
  #
  #   # Check whether a comment is spam
  #   #
  #
  #   client = Akismet::Client.new( 'apikey123',
  #     'http://jonahb.com',
  #     :app_name => 'jonahb.com',
  #     :app_version => '1.0' )
  #
  #   # assumes variables comment, post_url, request (a racklike HTTP request)
  #   spam = client.comment_check( request.remote_ip,
  #     request.user_agent,
  #     :content_type => 'comment',
  #     :referrer => request.headers[ 'HTTP_REFERER' ],
  #     :permalink => post_url,
  #     :comment_author => comment.author,
  #     :comment_author_email => comment.author_email,
  #     :comment_content => comment.body )
  #
  #   if spam
  #     # ...
  #   end
  #
  # @example
  #
  #   # Submit a batch of checks using a single TCP connection
  #   #
  #
  #
  #   client = Akismet::Client.new( 'apikey123',
  #     'http://jonahb.com',
  #     :app_name => 'jonahb.com',
  #     :app_version => '1.0' )
  #
  #   begin
  #     client.open
  #     comments.each do |comment|
  #       client.comment_check( ... )  # see example above
  #     end
  #   ensure
  #     client.close
  #   end
  #
  #   # ... or ...
  #
  #   Akismet::Client.open( 'apikey123',
  #     'http://jonahb.com',
  #     :app_name => 'jonahb.com',
  #     :app_version => '1.0' ) do |client|
  #     comments.each do |comment|
  #       client.comment_check( ... )  # see example above
  #     end
  #   end
  #
  #
  class Client

    # The API key obtained at akismet.com.
    # @return [String]
    attr_reader :api_key

    # The URL of the home page of the application making the request.
    # @return [String]
    attr_reader :home_url

    # The name of the application making the request, e.g "jonahb.com".
    # @return [String]
    attr_reader :app_name

    # The version of the application making the request, e.g. "1.0".
    # @return [String]
    attr_reader :app_version

    #@!group Constructors

    # @param [String] api_key
    #   The API key obtained at akismet.com.
    # @param [String] home_url
    #   The URL of the home page of the application making the request.
    # @option options [String] :app_name
    #   The name of the application making the request, e.g. "jonahb.com".
    #   Forms part of the User-Agent header submitted to Akismet.
    # @option options [String] :app_version
    #   The version of the application making the request, e.g. "1.0". Forms
    #   part of the User-Agent header submitted to Akismet. Ignored if
    #   :app_name is not privded.
    #
    def initialize( api_key, home_url, options = {} )
      @api_key = api_key
      @home_url = home_url
      @app_name = options[ :app_name ]
      @app_version = options[ :app_version ]
      @http_session = nil
    end

    #@!group Sessions

    # Initializes a client, opens it, yields it to the given block, and closes
    # it when the block returns. Takes the same arguments as {#initialize}.
    # @see #initialize
    # @yieldparam [Client] client
    # @return [Client]
    # @see #open
    #
    def self.open(*args)
      raise "Block required" unless block_given?
      client = new(*args)
      client.open { yield client }
      client
    end

    # Opens the client, creating a new TCP connection.
    #
    # If a block is given, yields to the block, closes the client when the
    # block returns, and returns the return value of the block. If a
    # block is not given, returns self and leaves the client open, relying on
    # the caller to close the client with {#close}.
    #
    # Note that opening and closing the client is only required if you want to
    # make several calls under one TCP connection. Otherwise, you can simply
    # call {#comment_check}, {#submit_ham}, or {#submit_spam}, which call
    # {#open} for you if necessary.
    #
    # Due to a peculiarity of the Akismet API, {#verify_key} always creates its
    # own connection.
    #
    # @yield
    #   If a block is given, the client is closed when the block returns.
    # @return [Object, self]
    #   If a block is given, the return value of the block; otherwise, +self+.
    # @raise [StandardError]
    #   The client is already open
    #
    def open
      raise "Already open" if open?

      @http_session = Net::HTTP.new( "#{ api_key }.rest.akismet.com", 80 )

      begin
        @http_session.start
        block_given? ? yield : self
      ensure
        close if block_given?
      end
    end

    # Closes the Client.
    # @return [self]
    # @see #open
    #
    def close
      @http_session.finish if open?
      @http_session = nil
      self
    end

    # Whether the Client is open.
    # @return [Boolean]
    #
    def open?
      @http_session && @http_session.started?
    end

    #@!group Akismet API

    # Checks the validity of the API key.
    # @return [Boolean]
    #
    def verify_key
      response = Net::HTTP.start( 'rest.akismet.com', 80 ) do |session|
        invoke( session, 'verify-key', :blog => home_url, :key => api_key )
      end

      unless %w{ valid invalid }.include?( response.body )
        raise_with_response response
      end

      response.body == 'valid'
    end

    # Checks whether a comment is spam. You are encouraged the submit, in
    # addition to the documented parameters, data about the client and the
    # comment submission. For example, if the client is an HTTP server,
    # include HTTP headers and environment variables.
    #
    # If the Client is not open, opens it for the duration of the call.
    #
    # @return [Boolean]
    # @raise [Akismet::Error]
    # @param [String] user_ip
    #   The IP address of the submitter of the comment.
    # @param [String] user_agent
    #   The user agent of the web browser submitting the comment. Typically
    #   the HTTP_USER_AGENT CGI variable. Not to be confused with the user
    #   agent of the Akismet library.
    # @option params [String] :referrer
    #   The value of the HTTP_REFERER header. Note that the parameter is
    #   spelled with two consecutive 'r's.
    # @option params [String] :permalink
    #   The permanent URL of the entry to which the comment pertains.
    # @option params [String] :comment_type
    #   'comment', 'trackback', 'pingback', or a made-up value like
    #   'registration'
    # @option params [String] :comment_author
    #   The name of the author of the comment.
    # @option params [String] :comment_author_email
    #   The email address of the author of the comment.
    # @option params [String] :comment_author_url
    #   A URL submitted with the comment.
    # @option params [String] :comment_content
    #   The text of the comment.
    #
    def check( user_ip, user_agent, params = {} )
      response = invoke_comment_method( 'comment-check',
        user_ip,
        user_agent,
        params )

      unless %w{ true false }.include?( response.body )
        raise_with_response response
      end

      response.body == 'true'
    end
    alias_method :comment_check, :check

    # Submits a comment that has been identified as not-spam (ham). If the
    # Client is not open, opens it for the duration of the call.
    #
    # @param (see #check)
    # @option (see #check)
    # @return [void]
    # @raise (see #check)
    #
    def ham( user_ip, user_agent, params = {} )
      response = invoke_comment_method( 'submit-ham',
        user_ip,
        user_agent,
        params )

      unless response.body == 'Thanks for making the web a better place.'
        raise_with_response response
      end
    end
    alias_method :submit_ham, :ham

    # Submits a comment that has been identified as spam. If the Client is not
    # open, opens it for the duration of the call.
    #
    # @param (see #check)
    # @option (see #check)
    # @return [void]
    # @raise (see #check)
    #
    def spam( user_ip, user_agent, params = {} )
      response = invoke_comment_method( 'submit-spam',
        user_ip,
        user_agent,
        params )

      unless response.body == 'Thanks for making the web a better place.'
        raise_with_response response
      end
    end
    alias_method :submit_spam, :spam


    private


    # Yields an HTTP session to the given block. Uses this instance's open
    # session if any; otherwise opens one and closes it when the block
    # returns.
    # @yield [Net::HTTP]
    #
    def in_http_session
      if open?
        yield @http_session
      else
        open { yield @http_session }
      end
    end

    # Raises an error given a response. The Akismet documentation states that
    # the HTTP headers of the response may contain error strings. I can't
    # seem to find them, so for now just raise an unknown error.
    # @param [Net::HTTPResponse] response
    #
    def raise_with_response( response )
      raise Error.new( Error::UNKNOWN, 'Unknown error' )
    end

    # @param [String] method_name
    # @param [String] user_ip
    # @param [String] user_agent
    # @param [Hash] params
    # @return [Net::HTTPResponse]
    # @raise [Akismet::Error]
    #   The API key is invalid.
    #
    def invoke_comment_method( method_name, user_ip, user_agent, params = {} )
      params = params.merge :blog => home_url,
        :user_ip => user_ip,
        :user_agent => user_agent

      response = in_http_session do |session|
        invoke( session, method_name, params )
      end

      if response.body == 'invalid'
        raise Error.new( Error::INVALID_API_KEY, 'Invalid API key' )
      end

      response
    end

    # @param [Net::HTTP] http_session
    #   A started HTTP session
    # @param [String] method_name
    # @return [Net::HTTPResponse]
    # @raise [Akismet::Error]
    #   An HTTP response other than 200 is received.
    #
    def invoke( http_session, method_name, params = {} )
      response = http_session.post( "/1.1/#{ method_name }",
        url_encode( params ),
        http_headers )

      unless response.is_a?( Net::HTTPOK )
        raise Error, "HTTP #{ response.code } received (expected 200)"
      end

      response
    end

    # @return [Hash]
    def http_headers
      {
        'User-Agent' => user_agent,
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    end

    # @return [String]
    def url_encode( hash = {} )
      hash.collect do |k, v|
        "#{ CGI.escape( k.to_s ) }=#{ CGI.escape( v.to_s ) }"
      end.join( "&" )
    end

    # From the Akismet documentation:
    #   If possible, your user agent string should always use the following
    #   format: Application Name/Version | Plugin Name/Version
    # @return [String]
    #
    def user_agent
      [ user_agent_app, user_agent_plugin ].compact.join( " | " )
    end

    # Returns nil if the Client was instantiated without an app_name.
    # @return [String]
    #
    def user_agent_app
      app_name && [ app_name, app_version ].compact.join( "/" )
    end

    # @return [String]
    def user_agent_plugin
      "Ruby Akismet/#{ Akismet::VERSION }"
    end

  end
end
