require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    apointments: Field::HasMany,
    availability: Field::HasMany,
    company: Field::String,
    confirmation_sent_at: Field::DateTime,
    confirmation_token: Field::String,
    confirmed_at: Field::DateTime,
    email: Field::String,
    encrypted_password: Field::String,
    failed_attempts: Field::Number,
    firstname: Field::String,
    jti: Field::String,
    lastname: Field::String,
    locked_at: Field::DateTime,
    remember_created_at: Field::DateTime,
    reset_password_sent_at: Field::DateTime,
    reset_password_token: Field::String,
    role: Field::Select.with_options(searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    services: Field::HasMany,
    unconfirmed_email: Field::String,
    unlock_token: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    apointments
    availability
    company
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    apointments
    availability
    company
    confirmation_sent_at
    confirmation_token
    confirmed_at
    email
    encrypted_password
    failed_attempts
    firstname
    jti
    lastname
    locked_at
    remember_created_at
    reset_password_sent_at
    reset_password_token
    role
    services
    unconfirmed_email
    unlock_token
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    apointments
    availability
    company
    confirmation_sent_at
    confirmation_token
    confirmed_at
    email
    encrypted_password
    failed_attempts
    firstname
    jti
    lastname
    locked_at
    remember_created_at
    reset_password_sent_at
    reset_password_token
    role
    services
    unconfirmed_email
    unlock_token
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(user)
  #   "User ##{user.id}"
  # end
end
