%w{
  version
  error
  client
}.each do |file|
  require "akismet/#{file}"
end
