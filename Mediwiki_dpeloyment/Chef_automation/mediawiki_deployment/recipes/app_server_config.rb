# installing the required packages in the App node.

node['app_packages'].each do |pkg|
    #using yum package to install the packages
    yum_package "#{pkg}" do
        action :install
        only_if {node['app_node']['new_installation']}
    end
end


# setup the app server services
execute 'starting the services' do
    command <<-eoh
	systemctl enable mariadb
	systemctl enable httpd
    eoh
	action :run
	only_if {node['app_node']['new_installation']}
end

# installing the mediawiki app
execute 'installing the mediawiki app' do
    command <<-eoh
    cd /home/username
	wget https://releases.wikimedia.org/mediawiki/1.33/mediawiki-1.33.0.tar.gz
	wget https://releases.wikimedia.org/mediawiki/1.33/mediawiki-1.33.0.tar.gz.sig
	gpg --verify mediawiki-1.33.0.tar.gz.sig mediawiki-1.33.0.tar.gz
	cd /var/www
    tar -zxf /home/username/mediawiki-1.33.0.tar.gz
    ln -s mediawiki-1.33.0/ mediawiki
    eoh
	action :run
	only_if {node['app_node']['new_installation']}
end

#setting up the apache
execute 'setting up the apache' do
    command <<-eoh
	cd /var/www
	ln -s mediawiki-1.33.0/ mediawiki
	chown -R apache:apache /var/www/mediawiki-1.33.0 
    eoh
	action :run
	only_if {node['app_node']['new_installation']}
end

service 'httpd' do
	action :restart
end

#Installing the firewall utility
yum_package "system-config-firewall-tui" do
	action :install
	only_if {node['app_node']['new_installation']}
end

execute 'Adding the firewall rules' do
    command <<-eoh
	firewall-cmd --add-service=http
	firewall-cmd --add-service=https
    eoh
	action :run
	only_if {node['app_node']['new_installation']}
end

#set the correct selinux context for the MediaWiki
execute 'Adding the firewall rules' do
    command <<-eoh
	restorecon -FR /var/www/mediawiki-1.33.0/
	restorecon -FR /var/www/mediawiki
    eoh
	action :run
	only_if {node['app_node']['new_installation']}
end