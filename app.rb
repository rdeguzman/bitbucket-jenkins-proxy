require 'sinatra'
require 'yaml'
require "open-uri"

jenkins_yml = YAML.load_file('jenkins.yml')[ENV['RACK_ENV']]

def set_response_headers
  content_type :json
  allowed_domain = '*'

  headers 'Access-Control-Allow-Origin' => "#{allowed_domain}",
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
end

def parse(req, jenkins)
  payload = JSON.parse( req.body.read )
  new = payload["push"]["changes"].first["new"]
  branch = new["name"]

  result = {}
  result[:branch]  = branch
  result[:job]     = params[:job] 
  result[:jenkins] = jenkins

  token = jenkins['token']
  
  #JENKINS_URL/job/proxy-test/buildWithParameters?token=TOKEN_NAME&branch=foobar
  result[:jenkins_url] = "http://#{jenkins['host']}/job/#{result[:job]}/buildWithParameters?token=#{token}&branch=#{branch}"

  return result
end

get '/' do
  set_response_headers
  content_type :json
  { :status => 'OK' }.to_json
end

# Use to mock tests
get '/job/*' do
  set_response_headers
  content_type :json
  { :status => 'OK' }.to_json
end

post '/build/:job' do
  set_response_headers
  content_type :json

  result = parse(request, jenkins_yml)

  url = result[:jenkins_url]
  open(url).read

  result.to_json
end
