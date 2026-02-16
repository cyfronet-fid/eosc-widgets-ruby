# EOSC Widgets Ruby

A project for an application aggregating shared functionalities (widgets) for the EOSC ecosystem, built using the Sinatra framework.

## Widgets and Functionalities

### 1. Favourites
Allows users to save and manage their favourite resources.
- **User Interface**: `/favourites`
- **API**:
  - `GET /api/favourites` - List of favourites in JSON format.
  - `POST /api/favourites` - Adding a new resource to favourites.
  - `DELETE /api/favourites` - Removing a resource from favourites (`pid` and `type` parameters).

### 2. User Profile
Displays technical session data and information about identity providers.
- **Address**: `/profile`
- **Features**:
  - Viewing UID for individual identity providers.
  - Secure preview and copying of the Access Token (utilizes Stimulus).
  - Automatic synchronization of the brand color (`brand-color`) saved in `localStorage`.

### 3. API Documentation
Interactive documentation of available API endpoints compliant with the OpenAPI 3.0 specification.
- **Swagger UI**: `/docs/swagger`
- **OpenAPI Specification**: `/openapi.yaml`

## Technologies
- **Backend**: Sinatra (Ruby)
- **Frontend**: Hotwired (Turbo & Stimulus), Bootstrap 5, Sass
- **Database**: PostgreSQL (ActiveRecord)
- **Authorization**: OmniAuth (OpenID Connect / Keycloak)

## Local Setup
1. Install Ruby dependencies: `bundle install`
2. Install JS dependencies: `yarn install`
3. Prepare the database: `rake db:create db:migrate widgets:migrate_all`
4. Build assets: `yarn build` and `yarn build:css`
5. Start the server: `rackup config.ru`

The application will be available at `http://localhost:9292` (default for Sinatra).
