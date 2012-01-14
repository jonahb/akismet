%w{
  version
  error
  client
}.each do |file|
  require File.join( File.dirname( __FILE__ ), 'akismet', file )
end