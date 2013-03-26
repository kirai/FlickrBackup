require 'fog'

class GlacierConnector
  def initialize(settings)
    @glacier = Fog::AWS::Glacier.new(aws_access_key_id:settings['access_key'], aws_secret_access_key:settings['secret_key'])
  end

  def test
    puts @glacier
  end
end