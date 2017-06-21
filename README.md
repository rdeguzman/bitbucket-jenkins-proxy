# Readme

## Development

	% bundle install
	% cp jenkins.yml.template jenkins.yml
	% cp rules.json.template rules.json
	% rerun "RACK_ENV=development ruby app.rb -o 0.0.0.0" #allows incoming connection 

## Rules DSL

	{
		"repo1": {
		    "master": "repo1-staging",
		    "develop": "repo1-test",
		    "default": "repo1-test"
		},
		"repo2": {
		    "master": "repo2-uat",
		    "develop": "repo2-test",
		    "default": "repo2-test"
		}
	}

## Testing

	% rerun "RACK_ENV=development ruby app.rb -o 0.0.0.0" # we need the server up for tests to pass
	% RACK_ENV=test rspec .

## Production

	% gem install -V bundler
	% bundle install --verbose --deployment --without development test

## Apache VirtualHost

	<VirtualHost *:80>
	  ServerName bitbucket-jenkins-proxy16u.datalink.loc
	  ServerAlias bitbucket-jenkins-proxy16u.datalink.loc
	  DocumentRoot /var/www/bitbucket-jenkins-proxy/public
	
	  DocumentRoot "/var/www/bitbucket-jenkins-proxy/public"
	  <Directory /var/www/bitbucket-jenkins-proxy/public >
	    Require all granted
	    Options FollowSymLinks
	    # This relaxes Apache security settings.
	    AllowOverride None
	    # MultiViews must be turned off.
	    Order allow,deny
	    Allow from all
	  </Directory>
	
	  CustomLog /var/log/apache2/bitbucket-jenkins-proxy.log combinedio
	
	  LogLevel crit
	</VirtualHost>	
	
