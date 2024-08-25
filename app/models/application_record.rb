# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  protected

  def self.group_by_day(admin)
    items = self.by_admin(admin)
    grouped_items = items.group_by { |item| item.created_at.to_date }
    count_by_day = grouped_items.transform_values(&:count)
    formatted_hash = count_by_day.transform_keys { |date| date.strftime('%d/%m/%Y') }
    formatted_hash
  end
end
