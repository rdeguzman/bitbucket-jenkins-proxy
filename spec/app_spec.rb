require 'byebug'
require File.expand_path '../spec_helper.rb', __FILE__

describe 'bitbucket-jenkins-proxy' do

  bitbucket_json = JSON.parse(File.read("spec/sample.json"))

  # https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html#EventPayloads-Push
  it 'sample.json should contain type:branch and name:name-of-branch' do
    new = bitbucket_json["push"]["changes"].first["new"]
    type = new["type"]
    name = new["name"]

    expect(type).to eq 'branch'
    expect(name).to eq 'name-of-branch'
  end

  it 'post /build' do
    post "/build", bitbucket_json.to_json, {'CONTENT_TYPE' => 'application/json'} 

    new = bitbucket_json["push"]["changes"].first["new"]
    branch_name = new["name"]

    expect(last_response).to be_ok
    json_response = JSON.parse(last_response.body)

    expect(json_response.has_key? 'branch').to be true
    expect(json_response.has_key? 'job').to be true
    expect(json_response.has_key? 'jenkins').to be true
    expect(json_response.has_key? 'jenkins_url').to be true

    expect(json_response['branch']).to eq branch_name

    jenkins_url = json_response['jenkins_url']
    puts "JENKINS_URL: #{jenkins_url}"

    expect( jenkins_url.to_s.include?("buildWithParameters?token") ).to be true
    expect( jenkins_url.to_s.include?("branch=#{branch_name}") ).to be true
  end
end
