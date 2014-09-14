default['huginn']['ruby_version'] = "2.0.0-p481"

default['huginn']['deploy_user']['name'] = "huginn"
default['huginn']['deploy_user']['group'] = "huginn"
default['huginn']['deploy_user']['home'] = "/home/huginn"
default['huginn']['deploy_user']['shell'] = "/bin/bash"

default['huginn']['database_password'] = "password"

default['huginn']['repository'] = "https://github.com/cantino/huginn.git"
default['huginn']['branch'] = "master"
default['huginn']['revision'] = "HEAD"
default['huginn']['keep_releases'] = 5

default['huginn']['rails_env'] = "production"

# default['huginn']['deploy_path'] = node['huginn']['deploy_user']['home']

default['huginn']['packages']['default'] = %w(libxslt-dev libxml2-dev curl libmysqlclient-dev libffi-dev libssl-dev)
default['huginn']['packages']['rhel'] = %w(libxslt-devel libxml2-devel mysql-devel curl libffi-devel openssl-devel patch)

default['mysql']['server_root_password'] = node['huginn']['database_password']
default['mysql']['remove_test_database'] = true
default['mysql']['remove_anonymous_users'] = true

default['authorization']['sudo']['include_sudoers_d'] = true

#default['huginn']['user'] = "huginn"
#default['huginn']['group'] = "huginn"
#default['huginn']['env']['invitation_code'] = "try-huginn-secretly"
