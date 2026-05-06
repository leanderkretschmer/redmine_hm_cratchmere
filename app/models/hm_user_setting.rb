class HmUserSetting < ActiveRecord::Base
  self.table_name = 'hm_user_settings'

  belongs_to :user

  validates :user_id, uniqueness: true
  validates :daily_target_minutes,  numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :weekly_target_minutes, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :max_break_minutes,     numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def self.for(user)
    find_or_initialize_by(user_id: user.id)
  end

  def effective_daily_target_minutes
    daily_target_minutes.to_i.positive? ? daily_target_minutes : plugin_default(:default_daily_target_minutes, 480)
  end

  def effective_weekly_target_minutes
    weekly_target_minutes.to_i.positive? ? weekly_target_minutes : plugin_default(:default_weekly_target_minutes, 2400)
  end

  def effective_max_break_minutes
    max_break_minutes.to_i.positive? ? max_break_minutes : plugin_default(:default_max_break_minutes, 60)
  end

  private

  def plugin_default(key, fallback)
    settings = Setting.plugin_redmine_hm_cratchmere || {}
    val = settings[key.to_s]
    val.to_i.positive? ? val.to_i : fallback
  end
end
