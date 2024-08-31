# frozen_string_literal: true

require 'date'

if Admin.exists?(email: 'admin@datescalendar.fr')
  admin = Admin.find_by(email: 'admin@datescalendar.fr').destroy
  puts "#{admin.email} has been deleted with all data"
end
admin = Admin.create!(email: 'admin@datescalendar.fr', password: 'azerty')

puts "Admin #{admin.email} created."

firstnames = %w[
  Alice Bob Claire David Eva Frank Grace Hugo Isabelle Jack
  Liam Emma Noah Olivia Aiden Ava Lucas Sophia Ethan Mia
  Mason Isabella Logan Charlotte James Amelia Benjamin Harper
  Elijah Evelyn Jacob Abigail Michael Ella Alexander Chloe
  William Lily Daniel Scarlett Sebastian Aria Henry Aurora
  Jackson Stella Owen Natalie Levi Luna Caleb Zoey
]

lastnames = %w[
  Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez
  Martinez Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor
  Moore Jackson White Harris Martin Thompson Robinson Clark Lewis
  Lee Walker Hall Allen Young King Wright Scott Torres Nguyen Hill
  Adams Baker Nelson Carter Mitchell Perez Roberts Turner Phillips
  Campbell Parker Evans Edwards Collins Stewart Sanchez Morris Rogers
  Reed Cook Morgan Bell Murphy Bailey Rivera Cooper Richardson Cox
  Howard Ward Flores Nelson Rivera Green Ramirez James Watson Brooks
  Kelly Sanders Price Bennett Wood Barnes Ross Henderson Coleman
  Jenkins Perry Powell Long Patterson Hughes Flores Jameson Weaver
  Palmer Walsh Foster Bryant
]

@services = [
  { title: 'Basic Cleaning', price: 50.0, time: 30 },
  { title: 'Deep Cleaning', price: 100.0, time: 60 },
  { title: 'Window Washing', price: 70.0, time: 45 },
  { title: 'Car Detailing', price: 150.0, time: 120 },
  { title: 'Garden Maintenance', price: 80.0, time: 90 },
  { title: 'Home Repair', price: 200.0, time: 180 },
  { title: 'Grocery Delivery', price: 30.0, time: 20 },
  { title: 'Pet Sitting', price: 60.0, time: 45 },
  { title: 'Personal Training', price: 120.0, time: 60 },
  { title: 'Tutoring', price: 40.0, time: 60 },
  { title: 'Massage Therapy', price: 90.0, time: 60 },
  { title: 'Haircut', price: 25.0, time: 30 },
  { title: 'Manicure', price: 40.0, time: 45 },
  { title: 'Pedicure', price: 45.0, time: 50 },
  { title: 'Resume Writing', price: 75.0, time: 120 },
  { title: 'Website Design', price: 500.0, time: 240 },
  { title: 'Translation', price: 100.0, time: 90 },
  { title: 'Photography', price: 200.0, time: 120 },
  { title: 'Event Planning', price: 350.0, time: 300 },
  { title: 'House Sitting', price: 70.0, time: 60 },
  { title: 'Music Lessons', price: 50.0, time: 45 },
  { title: 'Cooking Lessons', price: 80.0, time: 90 },
  { title: 'Yoga Class', price: 30.0, time: 60 },
  { title: 'Babysitting', price: 55.0, time: 120 },
  { title: 'Fitness Training', price: 110.0, time: 60 }
]

@sellers = []

def seller_actions(user)
  @services.sample(10).each do |service|
    Service.create!(service.merge(user:))
  end
  puts "#{user.services.count} services created for #{user.firstname}"

  Availability.create!(start_date: Time.now, end_date: "#{Date.today} 19:00", available: true, user:)
  Availability.create!(start_date: "#{Date.tomorrow} 07:00", end_date: "#{Date.tomorrow} 19:00", available: true, user:)
  Availability.create!(start_date: "#{Date.today + 2.days} 07:00",
                       end_date: "#{Date.today + 2.days} 10:30",
                       available: false, user:)
  Availability.create!(start_date: "#{Date.today + 2.days} 10:30",
                       end_date: "#{Date.today + 2.days} 18:00",
                       available: true, user:)
  puts "#{user.availabilities.count} availabilities created for #{user.firstname}"
end

def customer_actions(customer)
  seller = @sellers.sample
  availability = seller.availabilities.where(available: true).sample
  service = seller.services.sample
  start_date = availability.start_date
  end_date = start_date + service.time.to_i.minutes
  Appointment.create!(start_date:, end_date:, comment: "For my son.", seller:, customer:)
  @sellers.delete(seller)
end

# Create 10 Sellers
10.times do
  firstname = firstnames.sample
  lastname = lastnames.sample
  email = "#{firstname.downcase}.#{lastname.downcase}@example.com"
  password = 'azerty'
  role = 'seller'
  company = ['Company A', 'Company B', 'Company C'].sample

  customer = User.create!(
    firstname:,
    lastname:,
    email:,
    password:,
    company:,
    role:,
    admin:
  )

  firstnames.delete(firstname)
  lastnames.delete(lastname)
  puts "customer #{customer.firstname}, #{customer.lastname}, #{customer.role}, #{customer.company}"

  seller_actions(customer)
  @sellers << customer
end

# Create 10 Customers
10.times do
  firstname = firstnames.sample
  lastname = lastnames.sample
  email = "#{firstname.downcase}.#{lastname.downcase}@example.com"
  password = 'azerty'
  role = 'customer'

  customer = User.create!(
    firstname:,
    lastname:,
    email:,
    password:,
    role:,
    admin:
  )

  firstnames.delete(firstname)
  lastnames.delete(lastname)
  puts "User #{customer.firstname}, #{customer.lastname}, #{customer.role}, #{customer.company}"

  customer_actions(customer)
end
