require 'byebug'
require File.expand_path '../spec_helper.rb', __FILE__

describe 'bitbucket-jenkins-proxy' do


  def set_branch(p, name)
    p["push"]["changes"].first["new"]["name"] = name
    return p 
  end

  def set_repo(p, name)
    p["repository"]["name"] = name
    return p
  end

  before(:each) do
    @bitbucket_json = JSON.parse(File.read("spec/sample.json"))
  end


  # https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html#EventPayloads-Push
  it 'sample.json should contain type:branch and name:name-of-branch' do
    new = @bitbucket_json["push"]["changes"].first["new"]
    type = new["type"]
    name = new["name"]

    expect(type).to eq 'branch'
    expect(name).to eq 'DFMS-XXX'
  end

  it 'post /build returns 200 OK' do
    post "/build", @bitbucket_json.to_json, {'CONTENT_TYPE' => 'application/json'} 

    expect(last_response).to be_ok
  end

  it 'post /build returns { branch: "DFMS-XXX" }' do
    post "/build", @bitbucket_json.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)

    branch_name = @bitbucket_json["push"]["changes"].first["new"]["name"]

    expect(json_response.has_key? 'branch').to be true
    expect(json_response['branch']).to eq branch_name
  end

  it 'post /build returns { repository: "" }' do
    post "/build", @bitbucket_json.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)

    repo = @bitbucket_json["repository"]["name"]

    expect(json_response.has_key? 'repository').to be true
    expect(json_response['repository']).to eq repo
  end

  it 'post /build returns { .., jenkins: { host: "", token: "" } }' do
    post "/build", @bitbucket_json.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)

    expect(json_response.has_key? 'jenkins').to be true

    jenkins = json_response['jenkins']
    expect(jenkins['host']).to eq '127.0.0.1:4567'
    expect(jenkins['token']).to eq 'secret'
  end

  it 'post /build returns { .., jenkins_url: "http://JENKINS_URL/job/:job_name/buildWithParameters?token=secret&branch=DFMS-XXX" }' do
    post "/build", @bitbucket_json.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)

    expect(json_response.has_key? 'jenkins_url').to be true

    jenkins_url = json_response['jenkins_url']
    puts "JENKINS_URL: #{jenkins_url}"

    expect( jenkins_url.to_s.include?("buildWithParameters?token=secret") ).to be true
    expect( jenkins_url.to_s.include?("branch=DFMS-XXX") ).to be true
  end

  it 'post /build returns { status: OK } if repo and branch is OK' do
    payload = set_branch(@bitbucket_json, 'master')
    payload = set_repo(@bitbucket_json, 'iris')
    post "/build", payload.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)

    expect(json_response.has_key? 'status').to be true
    expect(json_response['status']).to eq true
  end

  it 'repo:scrap branch: DFMS-123 => jenkins: proxy-test' do
    payload = set_branch(@bitbucket_json, 'DFMS-123')

    post "/build", payload.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)
    expect(json_response['job']).to eq 'proxy-test'
  end

  it 'repo:scrap branch: develop => jenkins: proxy-test' do
    payload = set_branch(@bitbucket_json, 'develop')

    post "/build", payload.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)
    expect(json_response['job']).to eq 'proxy-test'
  end

  it 'repo:scrap branch: master => jenkins: proxy-staging' do
    payload = set_branch(@bitbucket_json, 'master')

    post "/build", payload.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)
    expect(json_response['job']).to eq 'proxy-staging'
  end


  it 'repo:does-not-exist branch: master => jenkins: proxy-staging' do
    payload = set_branch(@bitbucket_json, 'master')
    payload = set_repo(payload, 'foobar')

    post "/build", payload.to_json, {'CONTENT_TYPE' => 'application/json'} 

    json_response = JSON.parse(last_response.body)
    expect(json_response['status']).to eq false
  end

end
