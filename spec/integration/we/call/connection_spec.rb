require "spec_helper"

RSpec.describe We::Call::Connection do

  describe '#initialize', vcr: { cassette_name: 'vileplume' } do
    context 'without middlewares registered' do
      subject do
        described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5)
      end

      it 'has a string body' do
        response = subject.get('pokemon/45/')
        expect(response.body).to be_a String
      end

      it 'is JSON' do
        response = subject.get('pokemon/45/')
        expect(response.body).to match(/\"name\":\"vileplume\"/)
      end
    end

    context 'with json and hashie middlewares registered' do
      subject do
        described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
          conn.response :mashify
          conn.response :json, content_type: /\bjson$/
        end
      end

      it 'has a hash for a body' do
        response = subject.get('pokemon/45/')
        expect(response.body).to be_a Hash
      end

      it 'can access properties' do
        response = subject.get('pokemon/45/')
        expect(response.body).to include(name: 'vileplume')
      end
    end
  end

  context 'adapter configuration' do
    context 'when no adapter is specified' do
      subject do
        described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5)
      end

      it 'should have the default adapter' do
        expect(subject.builder.handlers.map(&:klass)).to contain_exactly(Faraday::Adapter::NetHttp, We::Call::Middleware::Client::DetectDeprecations)
      end
    end

    context 'when default adapter is specified' do
      subject do
        described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
          conn.adapter Faraday.default_adapter
        end
      end

      it 'only has Faraday.default_adapter adapter handler' do
        expect(subject.builder.handlers.map(&:klass)).to contain_exactly(Faraday::Adapter::NetHttp, We::Call::Middleware::Client::DetectDeprecations)
      end
    end

    context 'when :net_http_persistent adapter is specified' do
      subject do
        described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
          conn.adapter :net_http_persistent
        end
      end

      it 'only has NetHttpPersistent adapter handler' do
        expect(subject.builder.handlers.map(&:klass)).to contain_exactly(Faraday::Adapter::NetHttpPersistent, We::Call::Middleware::Client::DetectDeprecations)
      end
    end
  end
end
