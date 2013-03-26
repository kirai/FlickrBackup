require 'fog'
require 'debugger'

class GlacierConnector
  def initialize(settings)
    @glacier = Fog::AWS::Glacier.new(aws_access_key_id:settings['access_key'],
                                     aws_secret_access_key:settings['secret_key'],
                                     region:settings['region'])
    @vault = settings['vault']
  end

  def freeze(file)
    vault = @glacier.vaults.get(@vault)
    vault.archives.create(:body => file, :multipart_chunk_size => 1024*1024)
  end

end