%w{
  version
  error
  client
}.each do |file|
  require "akismet/#{file}"
end

# {Akismet} provides convenience methods that instantiate a {Akismet::Client}
# and invoke the Akismet API in one call. Before calling these methods, set
# {api_key} and {app_url}.
#
module Akismet
  class << self

    # The API key obtained at akismet.com. Set before calling the {Akismet}
    # class methods.
    # @return [String]
    attr_accessor :api_key

    # A URL that identifies the application making the request. Set before
    # calling the {Akismet} class methods.
    # @return [String]
    attr_accessor :app_url

    # The name of the application making the request
    # @return [String]
    attr_accessor :app_name

    # The version of the application making the request
    # @return [String]
    attr_accessor :app_version

    # (see Client#check)
    def check(user_ip, user_agent, params = {})
      with_client { |client| client.check user_ip, user_agent, params }
    end

    # (see Client#spam?)
    def spam?(user_ip, user_agent, params = {})
      with_client { |client| client.spam? user_ip, user_agent, params }
    end

    # (see Client#spam)
    def spam(user_ip, user_agent, params = {})
      with_client { |client| client.spam user_ip, user_agent, params }
    end

    # (see Client#ham)
    def ham(user_ip, user_agent, params = {})
      with_client { |client| client.ham user_ip, user_agent, params }
    end

    # (see Client.open)
    def open(&block)
      with_client(&block)
    end

    private

    def with_client(&block)
      raise "Set Akismet.api_key" unless api_key
      raise "Set Akismet.app_url" unless app_url
      Akismet::Client.open api_key, app_url, app_name: app_name, app_version: app_version, &block
    end
  end
end
