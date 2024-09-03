# config/initializers/oas_rails.rb
OasRails.configure do |config|
  # Basic Information about the API
  config.info.title = 'DatesCalendar API'
  config.info.summary = 'A simple Appointment API.'
  config.info.description = "[View on GitHub](https://github.com/metalzoid/datescalendar)
### DatesCalendar API Presentation

#### Introduction

We are pleased to present our Reservation API, developed with Ruby on Rails 7. This API is designed to efficiently manage reservations, allowing administrators to create users and offering different roles to users for flexible and personalized management.

#### Key Features

1. **User Creation by Admin**
   - Administrators can create users from a remote site.
   - Each user can have one of the following three roles: Seller, Customer, or Both.

2. **Role Management**
   - **Seller**: Sellers can offer services and manage their availability.
   - **Customer**: Customers can book services and leave comments.
   - **Both**: Users with this role can both sell services and book services offered by other sellers.

#### Data Models

1. **Service**
   - **Attributes**: title, price, time (in minutes)
   - **Description**: Represents the offers provided by sellers (or users with the Both role).

2. **Availability**
   - **Attributes**: start_date, end_date, available
   - **Description**: Indicates the periods of availability or unavailability of a seller or a user with the Both role.

3. **Appointments**
   - **Attributes**: start_date, end_date (automatically calculated if not specified and if one or more services are selected), price (calculated based on the specified services), customer comment, seller comment
   - **Description**: Represents the appointments booked by customers, including service details, dates, and comments.

#### Availability Retrieval

- **Complete Model**: Retrieve the full availability model.
- **Specified Interval**: Retrieve availability within a specified interval in minutes, e.g., `{ from: start_date, to: end_date }`.

#### Availability Creation

- **Time Slots**: Create availability with specified minimum and maximum hours, even if spanning multiple days.

#### Advanced Features

- **Automatic End Date Calculation**: If the end date is not specified when creating an appointment, it is automatically calculated based on the selected services.
- **Automatic Price Calculation**: The price of the appointment is automatically calculated based on the specified services.

#### Conclusion

Our Reservation API offers a comprehensive and flexible solution for managing reservations, users, and services. With its advanced features and modular structure, it enables efficient and personalized management of reservations, tailored to the needs of sellers and customers.

For more information or any questions, please do not hesitate to contact us at [gagnaire.flo@gmail.com](mailto:gagnaire.flo@gmail.com). We would be delighted to assist you in integrating this API into your system.

---

Thank you for your attention.

---
"
  config.info.contact.name = 'Florian GAGNAIRE'
  config.info.contact.email = 'gagnaire.flo@gmail.com'
  config.info.contact.url = 'http://florian-gagnaire.dev'
  config.info.version = '1.0.1'
  config.layout = 'application'
  config.ignored_actions = ['devise/passwords', 'devise/unlocks', 'users/registrations#index',
                            'users/registrations#destroy', 'users/registrations#cancel', 'users/registrations#edit',
                            'users/registrations#new']

  # Servers Information. For more details follow: https://spec.openapis.org/oas/latest.html#server-object
  config.servers = [{ url: 'https://datescalendar.fr', description: 'Production'}]

  # Tag Information. For more details follow: https://spec.openapis.org/oas/latest.html#tag-object
  # config.tags = [{ name: "services", description: "Manage the `amazing` Services." }]

  # Optional Settings (Uncomment to use)

  # Extract default tags of operations from namespace or controller. Can be set to :namespace or :controller
  # config.default_tags_from = :namespace

  # Automatically detect request bodies for create/update methods
  # Default: true
  # config.autodiscover_request_body = false

  # Automatically detect responses from controller renders
  # Default: true
  config.autodiscover_responses = false

  # API path configuration if your API is under a different namespace
  config.api_path = '/api/v1/'

  # #######################
  # Authentication Settings
  # #######################

  # Whether to authenticate all routes by default
  # Default is true; set to false if you don't want all routes to include secutrity schemas by default
  config.authenticate_all_routes_by_default = false

  # Default security schema used for authentication
  # Choose a predefined security schema
  # [:api_key_cookie, :api_key_header, :api_key_query, :basic, :bearer, :bearer_jwt, :mutual_tls]
  config.security_schema = :bearer_jwt

  # Custom security schemas
  # You can uncomment and modify to use custom security schemas
  # Please follow the documentation: https://spec.openapis.org/oas/latest.html#security-scheme-object
  #
  # config.security_schemas = {
  #  bearer:{
  #   "type": "apiKey",
  #   "name": "api_key",
  #   "in": "header"
  #  }
  # }

  # ###########################
  # Default Responses (Errors)
  # ###########################

  # The default responses errors are setted only if the action allow it.
  # Example, if you add forbidden then it will be added only if the endpoint requires authentication.
  # Example: not_found will be setted to the endpoint only if the operation is a show/update/destroy action.
  config.set_default_responses = false
  # config.possible_default_responses = [:not_found, :unauthorized, :forbidden]
  # config.response_body_of_default = { message: String }
end
