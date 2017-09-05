require "spec_helper"

RSpec.describe We::Call::Connection do
  describe '#initialize' do
    context 'when host is missing' do
      it 'raises ArgumentError' do
        expect { subject.new }.to raise_error(ArgumentError)
      end
    end

    context 'when app is missing' do
      subject { described_class.new(host: 'http://foo.com') }

      it 'raises We::Call::Connection::MissingApp' do
        expect { subject }.to raise_error(We::Call::Connection::MissingApp)
      end
    end

    context 'when timeout is missing' do
      subject { described_class.new(host: 'http://foo.com', app: 'foo', env: 'test') }

      it 'raises We::Call::Connection::MissingTimeout' do
        expect { subject }.to raise_error(We::Call::Connection::MissingTimeout)
      end
    end

    context 'when open_timeout is nilled somehow' do
      subject { described_class.new(host: 'http://foo.com', app: 'foo', env: 'test', timeout: 5, open_timeout: nil) }

      it 'raises We::Call::Connection::MissingOpenTimeout' do
        expect { subject }.to raise_error(We::Call::Connection::MissingOpenTimeout)
      end
    end

    context 'when all arguments are set other than env' do
      subject { described_class.new(host: 'http://foo.com', app: 'pokedex', timeout: 5) }

      context 'and it is guessable' do
        before { allow_any_instance_of(described_class).to receive(:guess_env) { 'test' } }

        it { is_expected.to be }
      end

      context 'and it is NOT guessable' do
        before { allow_any_instance_of(described_class).to receive(:guess_env) { nil } }

        it 'raises We::Call::Connection::MissingEnv' do
          expect { subject }.to raise_error(We::Call::Connection::MissingEnv)
        end
      end
    end
  end

  context 'when valid arguments are provided' do
    let(:valid_arguments) { { host: 'http://foo.com', app: 'pokedex', env: 'test', timeout: 5 } }

    subject { described_class.new(**valid_arguments) }

    it { is_expected.to be }

    it 'contains User-Agent header' do
      expect(subject.headers['User-Agent']).to eql('pokedex')
    end

    it 'contains X-App-Name header' do
      expect(subject.headers['X-App-Name']).to eql('pokedex')
    end

    it 'contains X-App-Env header' do
      expect(subject.headers['X-App-Env']).to eql('test')
    end

    it 'contains timeout option' do
      expect(subject.options[:timeout]).to eql(valid_arguments[:timeout])
    end

    it 'contains open_timeout option' do
      expect(subject.options[:open_timeout]).to eql(described_class::OPEN_TIMEOUT)
    end

    context 'when open_timeout is passed' do
      let(:valid_arguments_with_open_timeout) { valid_arguments.merge(open_timeout: 2) }

      subject { described_class.new(**valid_arguments_with_open_timeout) }

      it 'contains open_timeout option' do
        expect(subject.options[:open_timeout]).to eql(valid_arguments_with_open_timeout[:open_timeout])
      end
    end

    context 'when app needs to be guessed' do
      before { allow_any_instance_of(described_class).to receive(:rails_app_name) { 'test-app' } }

      let(:valid_arguments_without_env) { valid_arguments.tap { |h| h.delete(:app) } }

      subject { described_class.new(**valid_arguments_without_env) }

      it 'contains X-App-Name header' do
        expect(subject.headers['X-App-Name']).to eql('test-app')
      end
    end

    context 'with custom block' do
      subject do
        described_class.new(**valid_arguments) do |faraday|
          faraday.headers['Foo'] = 'bar'
        end
      end

      it 'sets custom headers' do
        expect(subject.headers).to include('Foo' => 'bar')
      end
    end

    context 'adapter configuration' do
      context 'when no adapter is specified' do
        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5)
        end

        it 'should have the default adapter' do
          expect(subject.builder.handlers.map(&:klass)).to contain_exactly(Faraday::Adapter::NetHttp, Faraday::Sunset)
        end
      end

      context 'when default adapter is specified' do
        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
            conn.adapter Faraday.default_adapter
          end
        end

        it 'only has Faraday.default_adapter adapter handler' do
          expect(subject.builder.handlers.map(&:klass)).to contain_exactly(Faraday::Adapter::NetHttp, Faraday::Sunset)
        end
      end

      context 'when :net_http_persistent adapter is specified' do
        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
            conn.adapter :net_http_persistent
          end
        end

        it 'only has NetHttpPersistent adapter handler' do
          expect(subject.builder.handlers.map(&:klass)).to contain_exactly(Faraday::Adapter::NetHttpPersistent, Faraday::Sunset)
        end
      end

      context 'when detect deprecations is truthy' do
        let(:builder_spy) { spy('QueryableBuilder') }

        before do
          allow(We::Call::Connection::QueryableBuilder).to receive(:new) { builder_spy }
        end

        context 'and config.detect_deprecations is left to default' do
          it 'register middleware with { active_support: true }' do
            subject
            expect(builder_spy).to have_received(:response).with(
              :sunset,
              active_support: true
            )
          end
        end

        context 'and config.detect_deprecations is set to :logger' do
          let(:logger) { spy('Logger') }

          before do
            @orig_detect_deprecations = We::Call::configuration.detect_deprecations
            We::Call::configuration.detect_deprecations = logger
          end

          after do
            We::Call::configuration.detect_deprecations = @orig_detect_deprecations
          end

          it 'register middleware with { logger: logger }' do
            subject
            expect(builder_spy).to have_received(:response).with(
              :sunset,
              logger: logger
            )
          end
        end
      end
    end
  end
end
