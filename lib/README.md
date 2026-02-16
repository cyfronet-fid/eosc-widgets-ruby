# lib/widgets

Directory intended for implementations specific to individual widgets.

## Widget Structure

Each widget should be located in its own subdirectory within `lib/widgets/` and can optionally contain the following structure:

- `models/` - ActiveRecord models specific to the widget.
- `migrations/` - Database migrations (run via `rake widgets:migrate[widget_name]`).
- `routes/` - Sinatra route definitions.
- `views/` - ERB views.

## Widget Registration

Widgets are automatically loaded in the `app.rb` file:

```ruby
Dir[File.join(settings.root, 'lib', 'widgets', '*', 'models', '*.rb')].sort.each { |f| require f }
Dir[File.join(settings.root, 'lib', 'widgets', '*', 'routes', '*.rb')].sort.each { |f| require f }
```

## Available Widgets

1. **favourites** - Management of favourite resources.
2. **profile** - Information about the logged-in user.
3. **documentation** - OpenAPI documentation and Swagger UI.
