deploy_revision node['huginn']['deploy_user']['home'] do
  repository node['huginn']['repository']
  revision node['huginn']['revision']
  keep_releases node['huginn']['keep_releases']
  rollback_on_error node['huginn']['rollback_on_error']
  # enable_submodules true
  # shallow_clone true

  user node['huginn']['deploy_user']['name']
  group node['huginn']['deploy_user']['group']

  environment "RAILS_ENV" => node['huginn']['rails_env'], "RBENV_VERSION" => node['huginn']['ruby_version']

  migrate false # We handle this manually below since it doesn't work well with rbenv

  action node['huginn']['deploy_action']

  symlink_before_migrate Hash.new # Disable default

  before_migrate do
    Chef::Log.info "Rewriting Gemfile/Procfile to use unicorn"
    rbenv_execute "Rewrite Gemfile/Procfile to use unicorn" do
      cwd release_path
      user new_resource.user

      ruby_version node['huginn']['ruby_version']

      command %{
        echo >> Gemfile
        echo "gem 'unicorn'" >> Gemfile

        sed -i 's#rails server#unicorn -c config/unicorn/production.rb#' Procfile
      }
    end

    # From https://github.com/poise/application_ruby/blob/master/providers/rails.rb
    Chef::Log.info "Running bundle install"
    directory "#{new_resource.deploy_to}/shared/vendor_bundle" do
      owner new_resource.user
      group new_resource.group
      mode '0755'
    end
    directory "#{release_path}/vendor" do
      owner new_resource.user
      group new_resource.group
      mode '0755'
    end
    link "#{release_path}/vendor/bundle" do
      to "#{new_resource.deploy_to}/shared/vendor_bundle"
    end

    common_groups = %w{development test cucumber staging}
    bundle_command = "bundle install --path=vendor/bundle --without #{common_groups}"

    rbenv_execute "Bundle Install" do
      cwd release_path
      user new_resource.user

      ruby_version node['huginn']['ruby_version']

      command bundle_command
    end

    Chef::Log.info "Creating rake secret (if required)"
    rbenv_execute "create-rake-secret" do
      user new_resource.user
      cwd release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{new_resource.deploy_to}/shared/rakesecret"

      command <<-EOH
      bundle exec rake secret > #{new_resource.deploy_to}/shared/rakesecret
      EOH
    end

    Chef::Log.info "Removing old dotenv config file"
    bash "remove-old-dotenv" do
      user new_resource.user
      cwd "#{new_resource.deploy_to}/shared"

      code <<-EOH
      rm -f dotenv
      EOH
    end

    Chef::Log.info "Copying .env.example to dotenv"
    bash "copy-example-dotenv" do
      user new_resource.user
      cwd release_path

      code <<-EOH
      cp .env.example #{new_resource.deploy_to}/shared/dotenv
      EOH
    end
    link "#{release_path}/.env" do
      to "#{new_resource.deploy_to}/shared/dotenv"
    end

    Chef::Log.info "Configuring new dotenv config file"
    bash "configure-dotenv" do
      user new_resource.user
      cwd "#{new_resource.deploy_to}/shared"

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
      user new_resource.user
      cwd release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{new_resource.deploy_to}/shared/rake-db-created"

      command <<-EOH
      bundle exec rake db:create db:migrate && touch #{new_resource.deploy_to}/shared/rake-db-created
      EOH
    end

    Chef::Log.info "Running rake db:seed (if required)"
    rbenv_execute "rake-db-seed" do
      user new_resource.user
      cwd release_path

      ruby_version node['huginn']['ruby_version']
      creates "#{new_resource.deploy_to}/shared/rake-db-seeded"

      command <<-EOH
      bundle exec rake db:seed && touch #{new_resource.deploy_to}/shared/rake-db-seeded
      EOH
    end

    Chef::Log.info "Running rake db:migrate"
    rbenv_execute "rake-db-migrate" do
      user new_resource.user
      cwd release_path

      ruby_version node['huginn']['ruby_version']

      command "bundle exec rake db:migrate"
    end
  end

  before_symlink do
    Chef::Log.info "Create directory layout in shared"
    %w(config config/unicorn log tmp tmp/pids tmp/sockets).each do |dir|
      directory "#{new_resource.deploy_to}/shared/#{dir}" do
        owner new_resource.user
        group new_resource.group
        recursive true
      end
    end

    Chef::Log.info "Write Unicorn Production Config"
    template "Write Unicorn Production Config" do
      owner new_resource.user
      group new_resource.group

      source "unicorn/production.rb.erb"
      path "#{new_resource.deploy_to}/shared/config/unicorn/production.rb"

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
      cwd release_path

      command "bundle exec foreman export upstart /etc/init -a huginn -u #{new_resource.user} -l log"
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
