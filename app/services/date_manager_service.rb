# frozen_string_literal: true
class DateManagerService
  def initialize(availability, params, user)
    @availability = availability
    @params = params
    @user = user
    @availabilities = []
  end

  def call
    verify_params
    start_date = @availability.start_date.to_datetime
    end_date = @availability.end_date.to_datetime

    create_daily_availabilities(start_date, end_date)
    @availabilities
  end

  private

  def verify_params
    required_params = %i[max_hour max_minutes min_hour min_minutes]
    missing_params = required_params.select { |param| @params[param].nil? }

    return if missing_params.empty?

    raise ArgumentError, "Paramètres requis manquants: #{missing_params.join(', ')}"
  end

  def create_daily_availabilities(start_date, end_date)
    while start_date < end_date
      current_day_end = calculate_current_day_end(start_date, end_date)
      new_start_date = calculate_new_start_date(start_date)
      temp = Availability.new(user: @user, available: @availability.available, start_date: new_start_date,
                                  end_date: current_day_end)
      @availabilities << temp
      start_date = advance_to_next_day(start_date)
    end
  end

  def calculate_current_day_end(start_date, end_date)
    current_day_end = start_date.change(hour: @params[:max_hour]&.to_i, min: @params[:max_minutes]&.to_i)
    current_day_end > end_date ? end_date : current_day_end
  end

  def calculate_new_start_date(start_date)
    if start_date == @availability.start_date.to_datetime && start_date.hour >= @params[:min_hour]&.to_i
      start_date
    else
      start_date.change(hour: @params[:min_hour]&.to_i, min: @params[:min_minutes]&.to_i)
    end
  end

  def advance_to_next_day(date)
    date.change(hour: 0, min: 0) + 1.day
  end
end
