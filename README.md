# Usecompass

A comprehensive tool to guide your Rails architecture by ensuring controllers call usecases, usecases have specs, rake tasks follow best practices, and all components have proper test coverage.

## Features

- ✅ **Controller Architecture**: Ensure controllers delegate to usecases
- ✅ **Usecase Testing**: Verify every usecase has corresponding spec
- ✅ **Rake Task Architecture**: Ensure rake tasks use usecases for business logic
- ✅ **Rake Task Testing**: Verify every rake task has corresponding spec
- ✅ **Individual Check Options**: Run specific checks with `-C`, `-S`, `-R` flags
- ✅ **Custom Spec Mappings**: Support non-standard spec file naming conventions
- ✅ **Flexible Exclusions**: Configure exclusions for controllers, actions, files
- ✅ **CI/CD Integration**: Exit codes for build pipeline integration

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'usecompass'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install usecompass
```

## Usage

### Initialize configuration

Create a `usecompass.yml` configuration file:

```bash
$ bundle exec usecompass init
```

### Basic usage

Run usecompass in your Rails project root:

```bash
$ bundle exec usecompass
# or explicitly
$ bundle exec usecompass check
```

### Command line options

#### Init command
```bash
$ usecompass init                   # Create usecompass.yml in current directory
$ usecompass init -r /path/to/project  # Create config in specified project
$ usecompass init --force           # Force overwrite existing config file
```

#### Check command (default)
```bash
$ usecompass -r /path/to/project    # Specify project root
$ usecompass -c /path/to/config.yml # Specify config file
$ usecompass --help                 # Show help

# Individual check options
$ usecompass -C                     # Check controllers only
$ usecompass -S                     # Check usecase specs only  
$ usecompass -R                     # Check rake usecase calls only
$ usecompass -R -S                  # Check rake specs only

# Output format options
$ usecompass --json                 # Output results in JSON format
$ usecompass -f json                # Alternative way to output JSON
$ usecompass --json -o report.json  # Output JSON to file
```

## Configuration

Create a `usecompass.yml` file in your project root to configure exclusions:

```yaml
exclusions:
  controllers:
    # Exclude entire controllers
    - "app/controllers/application_controller.rb"
    - "app/controllers/admin/health_check_controller.rb"
  
  controller_actions:
    # Exclude specific actions
    - controller: "app/controllers/admin/dashboard_controller.rb"
      actions: ["index", "show"]
    - controller: "app/controllers/api/v1/status_controller.rb"
      actions: ["health"]
  
  usecase_specs:
    # Exclude usecases from spec requirement
    - "layered/usecase/legacy/migration_usecase.rb"
  
  rake_specs:
    # Exclude rake files from spec requirement
    - "lib/tasks/legacy/old_task.rake"

# Custom spec file mappings for non-standard naming
custom_mappings:
  rakes:
    # Map rake files to their corresponding spec files
    - rake_file: "lib/tasks/organization_role_resource.rake"
      spec_file: "spec/lib/tasks/org_role_spec.rb"
    - rake_file: "lib/tasks/hoge_one.rake"
      spec_file: "spec/lib/tasks/hoge_one_1_spec.rb"
  
  usecases:
    # Map usecase files to their corresponding spec files
    - usecase_file: "layered/usecase/some_usecase.rb"
      spec_file: "spec/layered/usecase/some_custom_spec.rb"
```

## What it checks

### 1. Controllers call usecases

Ensures that controller actions call usecase classes instead of implementing business logic directly.

**Good:**
```ruby
class OrdersController < ApplicationController
  def create
    result = CreateOrderUsecase.new.perform(order_params)
    render json: result
  end
end
```

**Bad:**
```ruby
class OrdersController < ApplicationController
  def create
    # Business logic directly in controller
    order = Order.new(order_params)
    order.save!
    render json: order
  end
end
```

### 2. Usecases have specs

Ensures that every usecase file has a corresponding spec file.

- `layered/usecase/orders/create_order_usecase.rb` → `spec/layered/usecase/orders/create_order_usecase_spec.rb`
- `app/usecases/create_order_usecase.rb` → `spec/usecases/create_order_usecase_spec.rb`

### 3. Rake tasks call usecases

Ensures that rake tasks call usecase classes instead of implementing business logic directly.

**Good:**
```ruby
task :process_orders do
  ProcessOrdersUsecase.new.perform
end
```

**Bad:**
```ruby
task :process_orders do
  # Business logic directly in rake task
  Order.pending.each do |order|
    order.process!
    OrderMailer.confirmation(order).deliver
  end
end
```

### 4. Rake tasks have specs

Ensures that every rake task file has a corresponding spec file.

- `lib/tasks/orders.rake` → `spec/lib/tasks/orders_spec.rb`
- `lib/tasks/admin/cleanup.rake` → `spec/lib/tasks/admin/cleanup_spec.rb`

### 5. Custom spec mappings

For projects with non-standard naming conventions, you can define custom mappings:

- Instead of `organization_role_resource_spec.rb`, use `org_role_spec.rb`
- Map specific files to their custom spec locations
- Support for both rake tasks and usecases

## Exit codes

- `0`: All checks passed
- `1`: Violations found

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).