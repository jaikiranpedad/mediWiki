# installing the required packages in the db node.

node['db_packages'].each do |pkg|
    #using yum package to install the packages
    yum_package "#{pkg}" do
        action :install
        only_if {node['db_node']['new_installation']}
    end
end


# setup the DB

execute 'Setting up the db' do
    command <<-eoh
    systemctl start mariadb
    mysql_secure_installation
    CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'Pa55word';
    eoh
    action :run
end

# Runngin the required SQL queries

sql_query = "CREATE DATABASE wikidatabase;
            GRANT ALL PRIVILEGES ON wikidatabase.* TO 'wiki'@'localhost';
            FLUSH PRIVILEGES;"

run_sql_query(sql_query,"wiki@localhost",'Pa55word','MEDWIKDB1')


# function for running the sql query
def run_sql_query(sql_query,db_username,db_password,db_server)
    require 'tiny_tds'
    client = TinyTds::Client.new username: db_username, password: db_password, dataserver: db_server
    client.execute("#{sql_query}")
end