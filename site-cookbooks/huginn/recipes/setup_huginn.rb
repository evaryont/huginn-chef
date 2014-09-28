# node_database_password = node['huginn']['database_password'] # Set this here since it doesn't seem to like using the hash directly later

#deploy node['huginn']['deploy_user']['home'] do
application "huginn" do
  path node['huginn']['deploy_user']['home']

  repository node['huginn']['repository']
  revision node['huginn']['revision']
  #keep_releases node['huginn']['keep_releases']
  rollback_on_error false # true TODO CHANGEME

  #user node['huginn']['deploy_user']['name']
  owner node['huginn']['deploy_user']['name']
  group node['huginn']['deploy_user']['group']

  environment "RAILS_ENV" => node['huginn']['rails_env'], "RBENV_VERSION" => node['huginn']['ruby_version']

  migrate false
  # migration_command "bundle exec rake db:migrate"

  #restart_command ""

  # enable_submodules true
  # migrate true
  # migration_command "rake db:migrate"
  # environment "RAILS_ENV" => "production", "OTHER_ENV" => "foo"
  # shallow_clone true

  action :deploy #:force_deploy # or :rollback
  # restart_command "touch tmp/restart.txt"
  # git_ssh_wrapper "wrap-ssh4git.sh"
  # scm_provider Chef::Provider::Git # is the default, for svn: Chef::Provider::Subversion

  # before_migrate do

  #   # rbenv_execute "create/seed db" do
  #   #   ruby_version node['huginn']['ruby_version']
  #   #   cwd "#{node['huginn']['deploy_user']['home']}/current"
  #   #   command <<-EOH
  #   #     bundler exec rake db:create && bundler exec rake db:migrate && bundler exec rake db:seed && echo 1 > #{node['huginn']['deploy_user']['home']}/shared/RAKE-DB-CREATED
  #   #   EOH
  #   # end

  # end

  before_migrate do
    Chef::Log.info "Rewriting Gemfile/Procfile to use unicorn"
    rbenv_execute "Rewrite Gemfile/Procfile to use unicorn" do
      cwd new_resource.release_path
      user new_resource.owner

      ruby_version node['huginn']['ruby_version']

      command %{
        echo >> Gemfile
        echo "gem 'unicorn'" >> Gemfile

        sed -i 's#rails server#unicorn -c config/unicorn/production.rb#' Procfile
      }
    end

    # From https://github.com/poise/application_ruby/blob/master/providers/rails.rb
    Chef::Log.info "Running bundle install"
    directory "#{new_resource.path}/shared/vendor_bundle" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end
    directory "#{new_resource.release_path}/vendor" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end
    link "#{new_resource.release_path}/vendor/bundle" do
      to "#{new_resource.path}/shared/vendor_bundle"
    end

    common_groups = %w{development test cucumber staging}
    bundle_command = "bundle install --path=vendor/bundle --without #{common_groups}"

    rbenv_execute "Bundle Install" do
      cwd new_resource.release_path
      user new_resource.owner

      ruby_version node['huginn']['ruby_version']

      command bundle_command
    end

    Chef::Log.info "Creating rake secret (if required)"
    rbenv_execute "create-rake-secret" do
      user new_resource.owner
      cwd new_resource.release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{new_resource.path}/shared/rakesecret"

      command <<-EOH
      bundle exec rake secret > #{new_resource.path}/shared/rakesecret
      EOH
    end

    Chef::Log.info "Removing old dotenv config file"
    bash "remove-old-dotenv" do
      user new_resource.owner
      cwd "#{new_resource.path}/shared"

      code <<-EOH
      rm -f dotenv
      EOH
    end

    Chef::Log.info "Copying .env.example to dotenv"
    bash "copy-example-dotenv" do
      user new_resource.owner
      cwd release_path

      code <<-EOH
      cp .env.example #{new_resource.path}/shared/dotenv
      EOH
    end
    link "#{new_resource.release_path}/.env" do
      to "#{new_resource.path}/shared/dotenv"
    end

    Chef::Log.info "Configuring new dotenv config file"
    bash "configure-dotenv" do
      user new_resource.owner
      cwd "#{new_resource.path}/shared"

      code %{
      rakesecret=$(cat rakesecret)
      #{%q{sed -i "s/^\(APP_SECRET_TOKEN\s*=\s*\).*$/\1$rakesecret/" dotenv}}

      database_name=#{node['huginn']['database']['name']}
      database_pool=#{node['huginn']['database']['pool']}
      database_username=#{node['huginn']['database']['username']}
      database_password=#{node['huginn']['database']['password']}
      #database_port=#{node['huginn']['database']['port']}

      #{%q{sed -i "s/^\(DATABASE_NAME\s*=\s*\).*$/\1$database_name/" dotenv}}
      #{%q{sed -i "s/^\(DATABASE_POOL\s*=\s*\).*$/\1$database_pool/" dotenv}}
      #{%q{sed -i "s/^\(DATABASE_USERNAME\s*=\s*\).*$/\1$database_username/" dotenv}}
      #{%q{sed -i "s/^\(DATABASE_PASSWORD\s*=\s*\).*$/\1$database_password/" dotenv}}

      sed -i 's/^\(SMTP_DOMAIN\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_USER_NAME\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_PASSWORD\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_SERVER\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_PORT\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_AUTHENTICATION\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(SMTP_ENABLE_STARTTLS_AUTO\s*=\s*\).*$/\1TODO/' dotenv
      sed -i 's/^\(EMAIL_FROM_ADDRESS\s*=\s*\).*$/\1TODO/' dotenv

      echo >> dotenv
      echo RBENV_VERSION="#{node['huginn']['ruby_version']}" >> dotenv
      }
    end

    Chef::Log.info "Running rake db:create (if required)"
    rbenv_execute "rake-db-create" do
      user new_resource.owner
      cwd new_resource.release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{new_resource.path}/shared/rake-db-created"

      command <<-EOH
      bundle exec rake db:create db:migrate && touch #{new_resource.path}/shared/rake-db-created
      EOH
    end

    Chef::Log.info "Running rake db:seed (if required)"
    rbenv_execute "rake-db-seed" do
      user new_resource.owner
      cwd new_resource.release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{new_resource.path}/shared/rake-db-seeded"

      command <<-EOH
      bundle exec rake db:seed && touch #{new_resource.path}/shared/rake-db-seeded
      EOH
    end
  end

  # symlink_before_migrate Hash.new
  #   #"config/database.yml" => "config/database.yml",
  #   "dotenv" => ".env"
  # })

  # create_dirs_before_symlink

  before_symlink do
    Chef::Log.info "Create directory layout in shared"
    %w(config config/unicorn log tmp tmp/pids tmp/sockets).each do |dir|
      directory "#{new_resource.path}/shared/#{dir}" do
        owner new_resource.owner
        group new_resource.group
        recursive true
      end
    end

    Chef::Log.info "Write Unicorn Production Config"
    template "Write Unicorn Production Config" do
      owner new_resource.owner
      group new_resource.group

      source "unicorn/production.rb.erb"
      path "#{new_resource.path}/shared/config/unicorn/production.rb"

      variables({
        :huginn => node['huginn']
      })

      action :create
    end

    Chef::Log.info "Write Nginx Config"
    template "Write Nginx Config" do
      owner "root"
      group "root"

      source "nginx.conf.erb"
      path "/etc/nginx/conf.d/huginn.conf"

      variables({
        :huginn => node['huginn']
      })

      action :create
    end
  end

  symlinks(
    # Default
    "system" => "public/system",
    "pids" => "tmp/pids",
    "log" => "log",
    # Custom
    "config/unicorn" => "config/unicorn"
  )

  before_restart do
    Chef::Log.info "Export Huginn service"
    rbenv_execute "Export Huginn service" do
      ruby_version node['huginn']['ruby_version']
      cwd "#{node['huginn']['deploy_user']['home']}/current"

      command "bundle exec foreman export upstart /etc/init -a huginn -u #{node['huginn']['deploy_user']['name']} -l log"
    end

    Chef::Log.info "Enable/Restart Huginn service"
    service "huginn" do
      provider Chef::Provider::Service::Upstart
      action [:enable, :restart]
    end

    Chef::Log.info "Enable/Restart Nginx service"
    service "nginx" do
      action [:enable, :restart]
    end
  end

end

# application "huginn" do
#   path "#{node['huginn']['deploy_user']['home']}/huginn"
#   repository node['huginn']['repository']
#   checkout_branch node['huginn']['branch']
#   #revision node['huginn']['branch']

#   keep_releases node['huginn']['keep_releases']
#   rollback_on_error true

#   owner node['huginn']['deploy_user']['name']
#   group node['huginn']['deploy_user']['group']

#   rails do

#   end

#   unicorn do
#     bundler true
#     preload_app true
#     worker_processes 2
#     working_directory "#{node['huginn']['deploy_user']['home']}/huginn/current"
#   end

#   nginx_load_balancer do
#     init_style "upstart"
#     #only_if { node['roles'].include?('my-app_load_balancer') }
#     set_host_header true
#   end
# end
