require "spec_helper"

RSpec.describe We::Call::Connection do
  DEFAULT_MIDDLEWARES = [FaradayMiddleware::Gzip, Faraday::Sunset, Faraday::Request::Retry]

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
      before do
        allow(Rails).to receive(:application).and_return(app_class.new)
      end

      let(:valid_arguments_without_app) { valid_arguments.tap { |h| h.delete(:app) } }
      let(:app_class) { stub_const('WeCallTest::Application', Class.new) }

      subject { described_class.new(**valid_arguments_without_app) }

      it 'contains X-App-Name header' do
        expect(subject.headers['X-App-Name']).to eql('we-call-test')
      end

      context 'when app has only one segment' do
        let(:app_class) { stub_const('Test::Application', Class.new) }

        it 'contains X-App-Name header' do
          expect(subject.headers['X-App-Name']).to eql('test')
        end
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
      let(:handlers) { subject.builder.handlers.map(&:klass) }

      context 'when no adapter is specified' do

        before do
          We::Call::configuration.detect_deprecations = true
        end

        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5)
        end

        it 'should have the default adapter' do
          expect(handlers).to match_array(
            [described_class::DEFAULT_ADAPTER_CLASS].concat(DEFAULT_MIDDLEWARES)
          )
        end
      end

      context 'when default adapter is specified' do
        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
            conn.adapter described_class::DEFAULT_ADAPTER
          end
        end

        it 'is not repeated adapter handler' do
          expect(handlers).to match_array(
            [described_class::DEFAULT_ADAPTER_CLASS].concat(DEFAULT_MIDDLEWARES)
          )
        end
      end

      context 'when :net_http adapter is specified' do
        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
            conn.adapter :net_http
          end
        end

        it 'specifies NetHttp adapter handler' do
          expect(handlers).to include(Faraday::Adapter::NetHttp)
        end

        it 'skips FaradayMiddleware::Gzip' do
          expect(handlers).to_not include(FaradayMiddleware::Gzip)
        end
      end

      context 'when :net_http_persistent adapter is specified' do
        subject do
          described_class.new(host: 'http://pokeapi.co/api/v2/', app: 'pokedex', env: 'test', timeout: 5) do |conn|
            conn.adapter :net_http_persistent
          end
        end

        it 'specifies NetHttpPersistent adapter handler' do
          expect(handlers).to include(Faraday::Adapter::NetHttpPersistent)
        end

        it 'skips FaradayMiddleware::Gzip' do
          expect(handlers).to_not include(FaradayMiddleware::Gzip)
        end
      end

      context 'when detect deprecations is truthy' do
        let(:builder_spy) { spy('QueryableBuilder') }

        before do
          We::Call::configuration.detect_deprecations = true
          allow(We::Call::Connection::QueryableBuilder).to receive(:new) { builder_spy }
          allow(builder_spy).to receive(:use)
          allow(builder_spy).to receive(:response)
        end

        context 'and config.detect_deprecations is left to default' do
          it 'register middleware with { active_support: :auto }' do
            subject
            expect(builder_spy).to have_received(:response).with(
              :sunset,
              active_support: :auto,
              rollbar: :auto
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
              logger: logger,
              rollbar: :auto,
              active_support: :auto
            )
          end
        end
      end

      context 'when retry is disabled' do
        before do
          We::Call::configuration.retry = false
        end

        after do
          We::Call::configuration.retry = true
        end

        it 'does not register retry middleware' do
          expect(handlers).not_to include(Faraday::Request::Retry)
        end
      end

      context 'when retry is enabled' do
        let(:builder_spy) { spy('QueryableBuilder') }

        before do
          allow(We::Call::Connection::QueryableBuilder).to receive(:new) { builder_spy }
          allow(builder_spy).to receive(:use)
          allow(builder_spy).to receive(:response)
        end

        context 'when retry is used with default options' do
          it 'registers the middleware with the correct options' do
            subject
            expect(builder_spy).to have_received(:request).with(
              :retry,
              We::Call::Connection::DEFAULT_RETRY_OPTIONS
            )
          end

          context 'when options are overriden' do
            let(:options) { { max: 5, backoff_factor: 2 } }

            around do |example|
              We::Call::configuration.retry_options = options
              example.run
              We::Call::configuration.retry_options = {}
            end

            it 'registers the middleware with the correct options' do
              subject
              expect(builder_spy).to have_received(:request).with(
                :retry,
                We::Call::Connection::DEFAULT_RETRY_OPTIONS.merge(options)
              )
            end

            context 'when retry options are set on a connection' do
              let(:options) { { max: 3, backoff_factor: 2 } }
              let(:valid_arguments) { super().merge(retry_options: options) }

              it 'registers the middleware with the correct options' do
                subject
                expect(builder_spy).to have_received(:request).with(
                  :retry,
                  We::Call::Connection::DEFAULT_RETRY_OPTIONS.merge(options)
                )
              end
            end
          end

          context 'when exceptions are overriden' do
            let(:options) { { exceptions: [Faraday::ResourceNotFound] } }

            around do |example|
              We::Call::configuration.retry_options = options
              example.run
              We::Call::configuration.retry_options = {}
            end

            it 'registers the middleware with the correct options' do
              expected_options = We::Call::Connection::DEFAULT_RETRY_OPTIONS.dup
              expected_options[:exceptions] += options[:exceptions]

              subject
              expect(builder_spy).to have_received(:request).with(
                :retry,
                expected_options
              )
            end
          end
        end
      end
    end
  end
end
