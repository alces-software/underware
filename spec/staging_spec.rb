
# frozen_string_literal: true

require 'staging'
require 'alces_utils'

RSpec.describe Metalware::Staging do
  include AlcesUtils

  def manifest
    Metalware::Staging.manifest(metal_config)
  end

  def update(&b)
    Metalware::Staging.update(metal_config, &b)
  end

  it 'loads a blank file list if the manifest is missing' do
    expect(manifest.files).to be_a(Array)
    expect(manifest.files).to be_empty
  end

  describe '#push_file' do
    let :test_content { 'I am a test file' }
    let :test_sync { '/etc/some-random-location' }
    let :test_staging { File.join('/var/lib/metalware/staging', test_sync) }

    before :each do
      update { |staging| staging.push_file(test_sync, test_content) }
    end

    it 'writes the file to the correct location' do
      expect(File.exist?(test_staging)).to eq(true)
    end

    it 'writes the correct content' do
      expect(File.read(test_staging)).to eq(test_content)
    end

    it 'saves the default options' do
      expect(manifest.files.first.managed).to eq(false)
      expect(manifest.files.first.validator).to eq(nil)
    end

    it 'updates the manifest' do
      expect(manifest.files.first.staging).to eq(test_staging)
      expect(manifest.files.first.sync).to eq(test_sync)
    end

    it 'can push more files' do
      update do |staging|
        staging.push_file('second', '')
        staging.push_file('third', '')
      end
      expect(manifest.files.length).to eq(3)
      expect(manifest.files[1].staging).to eq(file_path.staging('second'))
      expect(manifest.files[2].staging).to eq(file_path.staging('third'))
    end

    it 'saves the additional options' do
      update do |staging|
        staging.push_file('other', '', managed: true, validator: 'validate')
      end

      expect(manifest.files.last.managed).to eq(true)
      expect(manifest.files.last.validator).to eq('validate')
    end
  end
end
