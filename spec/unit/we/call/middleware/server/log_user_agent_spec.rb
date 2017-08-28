require "spec_helper"

RSpec.describe We::Call::Middleware::Server::LogUserAgent do
  describe '#call' do
    let(:app_double) { double }
    let(:env) { { 'HTTP_USER_AGENT' => 'pokedex' } }

    subject { described_class.new(app_double) }

    before { allow(app_double).to receive(:call) }

    it 'will log user_agent' do
      expect(subject).to receive(:output).with("user_agent=pokedex;")
      subject.call(env)
    end

    context 'when X-App-Name provided' do
      let(:env_with_wework_app) { env.merge({ 'HTTP_X_APP_NAME' => 'pokedex' }) }

      it 'will log user_agent' do
        expect(subject).to receive(:output).with("user_agent=pokedex; app_name=pokedex;")
        subject.call(env_with_wework_app)
      end
    end

    context 'when X-App-Env provided' do
      let(:env_with_wework_env) { env.merge({ 'HTTP_X_APP_ENV' => 'test' }) }

      it 'will log user_agent' do
        expect(subject).to receive(:output).with("user_agent=pokedex; app_env=test;")
        subject.call(env_with_wework_env)
      end
    end

    context 'when X-App-Name and X-App-Env provided' do
      let(:env_with_wework_both) { env.merge({ 'HTTP_X_APP_NAME' => 'pokedex', 'HTTP_X_APP_ENV' => 'test' }) }

      it 'will log user_agent' do
        expect(subject).to receive(:output).with("user_agent=pokedex; app_name=pokedex; app_env=test;")
        subject.call(env_with_wework_both)
      end
    end
  end
end
