require 'sinatra'
require 'yaml'
require "open-uri"

jenkins_yml = YAML.load_file('jenkins.yml')[ENV['RACK_ENV']]
rules_json = JSON.parse(open("rules.json").read)

def set_response_headers
  content_type :json
  allowed_domain = '*'

  headers 'Access-Control-Allow-Origin' => "#{allowed_domain}",
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
end

def get_jenkins_job(rules, repo, branch, message)
  job_name = rules[repo][branch]
  if job_name.nil?
    job_name = rules[repo]["default"]
  end

  # Avoid infinite-loop in branch: build pipeline by checking message
  if message and message.start_with?("@@@build-version")
    job_name = nil
  end

  return job_name
end

def repo_exists_in_rules?(rules, repo)
  return !rules[repo].nil?
end

def parse(req, jenkins, rules)
  payload = JSON.parse( req.body.read )

  new = payload["push"]["changes"].first["new"]
  branch = new["name"]
  type = new["type"]
  repo = payload["repository"]["name"]
  message = new["target"]["message"]

  result = {}
  result[:branch]     = branch
  result[:jenkins]    = jenkins
  result[:repository] = repo 

  if type == "tag"
    result[:status]     = false
  elsif repo_exists_in_rules?(rules, repo)
    result[:job]        = get_jenkins_job(rules, repo, branch, message)
    result[:status]     = !result[:job].nil?
  else
    result[:status]     = false
  end

  #JENKINS_URL/job/proxy-test/buildWithParameters?token=TOKEN_NAME&branch=foobar
  result[:jenkins_url] = "http://#{jenkins['host']}/job/#{result[:job]}/buildWithParameters?token=#{jenkins['token']}&branch=#{branch}"

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

post '/build' do
  set_response_headers
  content_type :json

  result = parse(request, jenkins_yml, rules_json)

  if result[:status]
    url = result[:jenkins_url]
    logger.info("JENKINS: #{url}")
    open(url).read
  end

  result.to_json
end
