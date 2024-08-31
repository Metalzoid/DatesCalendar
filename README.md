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
