# Usecompass

A tool to guide your Rails usecase architecture by ensuring controllers call usecases and usecases have corresponding specs.

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

Create a `.usecompass.yml` configuration file:

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
$ usecompass init                   # Create .usecompass.yml in current directory
$ usecompass init -r /path/to/project  # Create config in specified project
$ usecompass init --force           # Force overwrite existing config file
```

#### Check command (default)
```bash
$ usecompass -r /path/to/project    # Specify project root
$ usecompass -c /path/to/config.yml # Specify config file
$ usecompass --help                 # Show help
```

## Configuration

Create a `.usecompass.yml` file in your project root to configure exclusions:

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

## Exit codes

- `0`: All checks passed
- `1`: Violations found

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).