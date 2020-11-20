require "spec_helper"

RSpec.describe We::Call::Configuration do

  describe "#app_env_header" do
    it "default value is X-App-Env" do
      expect(subject.app_env_header).to eql('X-App-Env')
    end
  end

  describe "#app_env_header=" do
    it "can set value" do
      subject.app_env_header = 'Some-Env-Header-Name'
      expect(subject.app_env_header).to eq('Some-Env-Header-Name')
    end
  end

  describe "#app_env=" do
    it "can set value" do
      subject.app_env = 'manual-env'
      expect(subject.app_env).to eq('manual-env')
    end
  end

  describe "#app_name=" do
    it "can set value" do
      subject.app_name = 'configured app name'
      expect(subject.app_name).to eq('configured app name')
    end
  end

  describe "#app_name_header" do
    it "default value is X-App-Name" do
      expect(subject.app_name_header).to eql('X-App-Name')
    end
  end

  describe "#app_name_header=" do
    it "can set value" do
      subject.app_name_header = 'Some-Header-Name'
      expect(subject.app_name_header).to eq('Some-Header-Name')
    end
  end

  describe "#detect_deprecations" do
    it "default value is nil" do
      expect(subject.detect_deprecations).to be_nil
    end
  end

  describe "#detect_deprecations=" do
    it "can set value" do
      subject.detect_deprecations = true
      expect(subject.detect_deprecations).to be true
    end
  end

  describe "#retry" do
    it "can set value" do
      subject.retry = true
      expect(subject.retry).to be true
    end
  end

  describe "#retry_options=" do
    it "can set value" do
      subject.retry_options = { max: 5 }
      expect(subject.retry_options).to eq({ max: 5 })
    end
  end
end
