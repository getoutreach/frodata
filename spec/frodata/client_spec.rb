# frozen_string_literal: true

require 'spec_helper'

describe FrOData::Client do
  subject { described_class }

  let(:instance_url) { 'http://myservice.com'}
  let(:base_path) { '/api'}
  let(:service_url) { instance_url + base_path }

  it "creates a client" do
    client = subject.new(
      instance_url: instance_url,
      base_path: base_path,
      client_id: 'client_id',
      client_secret: 'secret'
    )

    expect(client.options[:client_id]).to eql("client_id")
    expect(client.options[:client_secret]).to eql("secret")
    expect(client.options[:instance_url]).to eql(instance_url)
    expect(client.options[:base_path]).to eql("/api")

    stub_request(:get, "#{service_url}/$metadata").
        to_return(body: File.new('spec/fixtures/files/metadata.xml'), status: 200)

    service = client.service

    expect(service['Products']).to_not be_nil
    expect(service['Products'].name).to eql('Products')
    expect(service['Products'].type).to eql('ODataDemo.Product')
  end

  it "creates a client and inject a service instead of pulling the configured one" do
    service = FrOData::Service.new(service_url, name: 'Demo', metadata_file: 'spec/fixtures/files/metadata.xml')
    client = subject.new(
      instance_url: instance_url,
      base_path: base_path,
      client_id: 'client_id',
      client_secret: 'secret',
      service: service
    )

    expect(client.options[:client_id]).to eql("client_id")
    expect(client.options[:client_secret]).to eql("secret")
    expect(client.options[:instance_url]).to eql(instance_url)
    expect(client.options[:base_path]).to eql(base_path)

    expect(client.service).to eql service

    expect(service['Products']).to_not be_nil
    expect(service['Products'].name).to eql('Products')
    expect(service['Products'].type).to eql('ODataDemo.Product')
  end

end
