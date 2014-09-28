default['huginn']['ruby_version'] = "2.0.0-p481"

default['huginn']['deploy_user']['name'] = "huginn"
default['huginn']['deploy_user']['group'] = "huginn"
default['huginn']['deploy_user']['home'] = "/home/huginn"
default['huginn']['deploy_user']['shell'] = "/bin/bash"

default['huginn']['repository'] = "https://github.com/cantino/huginn.git"
default['huginn']['branch'] = "master"
default['huginn']['revision'] = "HEAD"
default['huginn']['keep_releases'] = 5

default['huginn']['rails_env'] = "production"

# default['huginn']['deploy_path'] = node['huginn']['deploy_user']['home']

default['huginn']['packages']['default'] = %w(libxslt-dev libxml2-dev curl libffi-dev libssl-dev)
default['huginn']['packages']['rhel'] = %w(libxslt-devel libxml2-devel curl libffi-devel openssl-devel patch)

# default['huginn']['database']['adapter'] = "mysql2"
# default['huginn']['database']['encoding'] = "utf8"
# default['huginn']['database']['reconnect'] = "true"
default['huginn']['database']['name'] = "huginn"
default['huginn']['database']['pool'] = 5
default['huginn']['database']['username'] = "root"
default['huginn']['database']['password'] = "Ch4ng3M3!"
# default['huginn']['database']['host'] = "your-domain-here.com"
default['huginn']['database']['port'] = "3306"
# default['huginn']['database']['socket'] = "/tmp/mysql.sock"

default['mysql']['server_root_password'] = node['huginn']['database']['password']
default['mysql']['port'] = node['huginn']['database']['port']
default['mysql']['remove_test_database'] = true
default['mysql']['remove_anonymous_users'] = true

default['authorization']['sudo']['include_sudoers_d'] = true

# See https://supermarket.getchef.com/cookbooks/nginx for options
default['nginx']['user'] = node['huginn']['deploy_user']['name']
default['nginx']['group'] = node['huginn']['deploy_user']['group']
# default['nginx']['worker_processes'] = 2
default['nginx']['worker_connections'] = "1024"

#default['huginn']['user'] = "huginn"
#default['huginn']['group'] = "huginn"
#default['huginn']['env']['invitation_code'] = "try-huginn-secretly"
