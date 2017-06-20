# Readme

## Development

	% bundle install
	% cp jenkins.yml.template jenkins.yml
	% ruby app.rb -o 0.0.0.0 #allows incoming connection 

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
	
