require 'date'
require 'net/http'
require 'uri'

module Akismet

  class Client

    # The API key obtained at akismet.com
    # @return [String]
    attr_reader :api_key

    # A URL that identifies the application making the request
    # @return [String]
    attr_reader :app_url

    # The name of the application making the request
    # @return [String]
    attr_reader :app_name

    # The version of the application making the request
    # @return [String]
    attr_reader :app_version

    # @!group Constructors

    # @param [String] api_key
    #   The API key obtained at akismet.com
    # @param [String] app_url
    #   The URL of the home page of the application making the request
    # @option options [String] :app_name
    #   The name of the application making the request, e.g. "jonahb.com".
    #   Forms part of the User-Agent header submitted to Akismet.
    # @option options [String] :app_version
    #   The version of the application making the request, e.g. "1.0". Forms
    #   part of the User-Agent header submitted to Akismet. Ignored if
    #   :app_name is not provided.
    #
    def initialize(api_key, app_url, options = {})
      @api_key = api_key
      @app_url = app_url
      @app_name = options[ :app_name ]
      @app_version = options[ :app_version ]
      @http_session = nil
    end

    # @!group Managing Connections

    # Initializes a client, opens it, yields it to the given block, and closes
    # it when the block returns. Allows you to perform several operations over
    # a single TCP connection.
    # @param (see #initialize)
    # @option (see #initialize)
    # @yieldparam [Client] client
    # @return [Object]
    #   The return value of the block
    # @see #open
    #
    def self.open(api_key, app_url, options = {})
      raise "Block required" unless block_given?
      client = new(api_key, app_url)
      client.open { yield client }
    end

    # Opens the client, creating a new TCP connection.
    #
    # If a block is given, yields to the block, closes the client when the
    # block returns, and returns the return value of the block. If a
    # block is not given, returns self and leaves the client open, relying on
    # the caller to close the client with {#close}.
    #
    # Note that opening and closing the client is only required if you want to
    # make several calls over one TCP connection. Otherwise, you can simply
    # call {#spam?}, {#check}, {#ham}, or {#spam}, which call {#open} for you
    # if necessary.
    #
    # Due to a peculiarity of the Akismet API, {#verify_key} always creates its
    # own connection.
    #
    # @overload open
    #   Opens the client, yields to the block, and closes the client when the
    #   block returns.
    #   @yield
    #     A block to be called when the client is open
    #   @return [Object]
    #     The return value of the block
    #   @raise [StandardError]
    #     The client is already open    
    # @overload open
    #   @return [self]
    #   @raise [StandardError]
    #     The client is already open
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

    # @!group Verifying Keys

    # Checks the validity of the API key.
    # @return [Boolean]
    #
    def verify_key
      response = Net::HTTP.start('rest.akismet.com', 80) do |session|
        invoke session, 'verify-key', blog: app_url, key: api_key
      end

      unless %w{ valid invalid }.include?(response.body)
        raise_with_response response
      end

      response.body == 'valid'
    end

    # @!macro akismet_method
    #   @param [String] user_ip
    #     The comment author's IP address
    #   @param [String] user_agent
    #     The comment author's user-agent
    #   @param [Hash{Symbol => Object}] params
    #     Optional parameters. To maximize accuracy, pass as many as possible.
    #   @option params [String] :referrer
    #     The value of the HTTP_REFERER header. Note that the parameter is
    #     spelled with two consecutive 'r's.
    #   @option params [String] :post_url
    #     The URL of the post, article, etc. on which the comment was made
    #   @option params [DateTime] :post_modified_at
    #     The date and time the post was last modified
    #   @option params [String] :type
    #     Suggested values include 'comment', 'trackback', and 'pingback'
    #   @option params [String] :text
    #     The text of the comment
    #   @option params [DateTime] :created_at
    #     The date and time the comment was created
    #   @option params [String] :author
    #     The comment author's name
    #   @option params [String] :author_email
    #     The comment author's email address
    #   @option params [String] :author_url
    #     The comment author's personal URL
    #   @option params [Array<String>] :languages
    #     The ISO 639-1 codes of the languages in use on the site where the
    #     comment appears
    #   @option params [Boolean] :test
    #     When set to true, Akismet does not use the comment to train the filter
    #   @option params [Hash{Symbol, String => Object}] :env
    #     Environment variables such as HTTP headers related to the comment
    #     submission
    #   @raise [Akismet::Error]
    #     The Akismet service returned an error
    #   @raise [ArgumentError]
    #     An environment variable conflicts with a built-in parameter
    #   @raise [ArgumentError]
    #     Invalid param

    # @!group Checking

    # Checks whether a comment is spam and whether it is "blatant."
    # @!macro akismet_method
    # @return [(Boolean, Boolean)]
    #   An array containing two booleans. The first indicates whether the
    #   comment is spam. The second indicates whether it is "blatant,"
    #   i.e. whether it can be deleted without review.
    #
    def check(user_ip, user_agent, params = {})
      response = invoke_comment_method('comment-check',
        user_ip,
        user_agent,
        params)

      unless %w{ true false }.include?(response.body)
        raise_with_response response
      end

      [
        response.body == 'true',
        response['X-akismet-pro-tip'] == 'discard'
      ]
    end
    alias_method :comment_check, :check

    # Checks whether a comment is spam.
    # @!macro akismet_method
    # @return [Boolean]
    #
    def spam?(user_ip, user_agent, params = {})
      check(user_ip, user_agent, params)[0]
    end

    # @!group Reporting

    # Submits a comment that has been identified as not-spam (ham).
    # @!macro akismet_method
    # @return [void]
    #
    def ham(user_ip, user_agent, params = {})
      response = invoke_comment_method('submit-ham',
        user_ip,
        user_agent,
        params)

      unless response.body == 'Thanks for making the web a better place.'
        raise_with_response response
      end
    end
    alias_method :submit_ham, :ham

    # Submits a comment that has been identified as spam.
    # @!macro akismet_method
    # @return [void]
    #
    def spam(user_ip, user_agent, params = {})
      response = invoke_comment_method('submit-spam',
        user_ip,
        user_agent,
        params)

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

    # @param [Net::HTTPResponse] response
    def raise_with_response( response )
      raise Error, response['X-akismet-debug-help'] || 'Unknown error'
    end

    # @param [String] method_name
    # @param [String] user_ip
    # @param [String] user_agent
    # @param [Hash] params
    # @return [Net::HTTPResponse]
    # @raise [ArgumentError]
    #   An environment variable conflicts with a built-in parameter
    # @raise [ArgumentError]
    #   Invalid parameter
    #
    def invoke_comment_method(method_name, user_ip, user_agent, params = {})
      env = params[:env] || {}

      for key in env.keys
        if PARAM_TO_API_PARAM.has_value?(key.to_sym)
          raise ArgumentError, "Environment variable '#{key}' conflicts with built-in API parameter"
        end
      end

      params = params.each_with_object(Hash.new) do |(name, value), api_params|
        next if name == :env
        api_name = PARAM_TO_API_PARAM[name] || raise(ArgumentError, "Invalid param: #{name}")
        api_params[api_name] = value
      end

      params = env.merge(params).merge(blog: app_url, user_ip: user_ip, user_agent: user_agent)

      in_http_session do |session|
        invoke session, method_name, params
      end
    end

    # @param [Net::HTTP] http_session
    #   A started HTTP session
    # @param [String] method_name
    # @return [Net::HTTPResponse]
    # @raise [Akismet::Error]
    #   An HTTP response other than 200 is received.
    #
    def invoke(http_session, method_name, params = {})
      params[:blog_charset] = 'UTF-8'

      params = params.collect do |name, value|
        [name.to_s.encode('UTF-8'), format(value).encode('UTF-8')]
      end

      response = http_session.post("/1.1/#{ method_name }",
        URI.encode_www_form(params),
        http_headers)

      unless response.is_a?( Net::HTTPOK )
        raise Error, "HTTP #{ response.code } received (expected 200)"
      end

      response
    end

    # @param [Object] object
    # @return [String]
    def format(object)
      case object
      when DateTime
        object.iso8601
      when TrueClass
        '1'
      when FalseClass
        '0'
      when Array
        object.collect { |element| format(element) }.join(', ')
      else
        object.to_s
      end
    end

    # @return [Hash]
    def http_headers
      {
        'User-Agent' => user_agent,
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    end

    # From the Akismet documentation:
    #   If possible, your user agent string should always use the following
    #   format: Application Name/Version | Plugin Name/Version
    # @return [String]
    #
    def user_agent
      [user_agent_app, user_agent_plugin].compact.join(" | ")
    end

    # Returns nil if the Client was instantiated without an app_name.
    # @return [String]
    #
    def user_agent_app
      app_name && [app_name, app_version].compact.join("/")
    end

    # @return [String]
    def user_agent_plugin
      "Ruby Akismet/#{ Akismet::VERSION }"
    end

    PARAM_TO_API_PARAM = {
      referrer: :referrer,
      post_url: :permalink,
      post_modified_at: :comment_post_modified_gmt,
      text: :comment_content,
      created_at: :comment_date_gmt,
      type: :comment_type,
      author: :comment_author,
      author_url: :comment_author_url,
      author_email: :comment_author_email,
      languages: :blog_lang,
      user_role: :user_role,
      test: :is_test,
    }

  end
end
