require "spec_helper"

describe We::Call do
  it "has a version number" do
    expect(We::Call::VERSION).to be_a(String)
  end

  describe "#configure" do
    before do
      We::Call.configure do |config|
        config.app_name_header = 'X-Some-Other-Thing'
      end
    end

    it 'contains X-Some-Other-Thing header' do
      conn = We::Call::Connection.new(host: 'http://foo.com', app: 'pokedex', env: '123', timeout: 5)
      expect(conn.headers['X-Some-Other-Thing']).to eql('pokedex')
    end
  end
end
