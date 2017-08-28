require 'spec_helper'
require 'active_support'

RSpec.describe We::Call::Middleware::Client::DetectDeprecations do

  let(:app) { double(:app) }
  let(:options) { {} }

  let(:response_headers) { {} }
  let(:response) { Faraday::Response.new(env) }

  let(:env) do
    Faraday::Env.from({
      url: 'http://example.com/foo', body: nil, request: {},
      request_headers: Faraday::Utils::Headers.new,
      response_headers: Faraday::Utils::Headers.new(response_headers)
    })
  end

  subject { described_class.new(app, options) }

  describe '#call' do

    before do
      allow(app).to receive(:call) { response }
    end

    context 'when no sunset header' do
      it 'calls app and calls on_complete' do
        response = Faraday::Response.new(env)
        expect(app).to receive(:call) { response }
        expect(response).to receive(:on_complete)
        subject.call(env)
      end

      it 'ActiveSupport::Deprecation.warn will not be called' do
        expect(ActiveSupport::Deprecation).not_to receive(:warn)
        subject.call(env)
      end
    end

    context 'when sunset header is set' do
      let(:sunset_date) { DateTime.new(2050,2,3,4,5,6,'+00:00') }

      let(:response_headers) { { sunset: sunset_date.httpdate } }

      it 'raise NoOutputForWarning' do
        expect { subject.call(env) }.to raise_error(described_class::NoOutputForWarning)
      end

      context 'and active_support option is enabled' do
        let(:options) { { active_support: true } }

        it 'ActiveSupport::Deprecation.warn will be called' do
          expect(ActiveSupport::Deprecation).to receive(:warn).with(
            "Endpoint http://example.com/foo is deprecated for removal on #{sunset_date.iso8601}"
          )
          subject.call(env)
        end
      end

      context 'and logger option is enabled' do
        let(:logger) { double }
        let(:options) { { logger: logger } }

        it 'ActiveSupport::Deprecation.warn will be called' do
          expect(logger).to receive(:warn).with(
            "Endpoint http://example.com/foo is deprecated for removal on #{sunset_date.iso8601}"
          )
          subject.call(env)
        end
      end

    end
  end

end
