default['huginn']['ruby_version'] = "2.0.0-p481"

default['huginn']['deploy_user']['name'] = "huginn"
default['huginn']['deploy_user']['group'] = "huginn"
default['huginn']['deploy_user']['home'] = "/home/huginn"
default['huginn']['deploy_user']['shell'] = "/bin/bash"

default['huginn']['repository'] = "https://github.com/cantino/huginn.git"
default['huginn']['branch'] = "master"
default['huginn']['revision'] = "HEAD"
default['huginn']['keep_releases'] = 5
default['huginn']['rollback_on_error'] = true
default['huginn']['deploy_action'] = :deploy # or :force_deploy

# default['huginn']['deploy_path'] = node['huginn']['deploy_user']['home']

default['huginn']['packages']['default'] = %w(libxslt-dev libxml2-dev curl libffi-dev libssl-dev)
default['huginn']['packages']['rhel'] = %w(libxslt-devel libxml2-devel curl libffi-devel openssl-devel patch)

force_default['authorization']['sudo']['include_sudoers_d'] = true

# See https://supermarket.getchef.com/cookbooks/nginx for options
force_default['nginx']['user'] = node['huginn']['deploy_user']['name']
force_default['nginx']['group'] = node['huginn']['deploy_user']['group']
# force_default['nginx']['worker_processes'] = 2
force_default['nginx']['worker_connections'] = "1024"

default['huginn']['env'] = {
    "APP_SECRET_TOKEN" => "$(cat '#{node['huginn']['deploy_user']['home']}/shared/rakesecret')",
    "DATABASE_NAME" => "huginn",
    "DATABASE_USERNAME" => "root",
    "DATABASE_PASSWORD" => "Ch4ng3M3!",
    "DATABASE_POOL" => "5",
    "DATABASE_ADAPTER" => "mysql2",
    "DATABASE_ENCODING" => "utf8mb4",
    "DATABASE_RECONNECT" => "true",
    "DATABASE_HOST" => "localhost",
    "DATABASE_PORT" => "3306",
    "RBENV_VERSION" => node['huginn']['ruby_version'],
    "RAILS_ENV" => "production"
}

force_default['mysql']['server_root_password'] = node['huginn']['env']['DATABASE_PASSWORD']
force_default['mysql']['port'] = node['huginn']['env']['DATABASE_PORT']
force_default['mysql']['remove_test_database'] = true
force_default['mysql']['remove_anonymous_users'] = true
