module RedmineHmCratchmere
  class Snapshot
    def initialize(user, user_setting = nil, now: Time.current)
      @user    = user
      @setting = user_setting || HmUserSetting.for(user)
      @tz      = user.time_zone || Time.zone
      @now     = now
    end

    def to_h
      open_entry        = HmWorkEntry.for_user(@user).open.order(started_at: :desc).first
      todays_completed  = HmWorkEntry.for_user(@user).completed.on_day(@tz, today)
      worked_completed  = todays_completed.to_a.sum { |e| e.net_seconds(as_of: @now) }
      worked_open       = open_entry ? open_entry.net_seconds(as_of: @now) : 0
      break_total_today = todays_completed.to_a.sum { |e| e.total_break_seconds(as_of: @now) }
      break_total_today += open_entry.total_break_seconds(as_of: @now) if open_entry

      current_break_started_at = open_entry&.current_break&.started_at
      current_break_seconds    = current_break_started_at ? (@now - current_break_started_at).to_i : 0

      state =
        if open_entry.nil?
          'idle'
        elsif open_entry.paused?
          'on_break'
        else
          'working'
        end

      settings = Setting.plugin_redmine_hm_cratchmere || {}
      daily_target_seconds = @setting.effective_daily_target_minutes.to_i * 60
      max_break_seconds    = @setting.effective_max_break_minutes.to_i * 60
      overtime_threshold   = (positive_int(settings['overtime_threshold_minutes']) || 480) * 60
      eu_break_after       = (positive_int(settings['eu_break_required_after_minutes']) || 360) * 60
      eu_max_daily         = (positive_int(settings['eu_max_daily_minutes']) || 600) * 60
      poll_interval        = positive_int(settings['poll_interval_seconds']) || 30

      {
        state: state,
        as_of_unix: @now.to_i,
        work_started_at_unix: open_entry&.started_at&.to_i,
        current_break_started_at_unix: current_break_started_at&.to_i,
        worked_seconds_today: worked_completed + worked_open,
        current_break_seconds: current_break_seconds,
        total_break_seconds_today: break_total_today,
        daily_target_seconds: daily_target_seconds,
        max_break_seconds: max_break_seconds,
        overtime_threshold_seconds: overtime_threshold,
        eu_break_required_after_seconds: eu_break_after,
        eu_max_daily_seconds: eu_max_daily,
        notify_target_reached: !!@setting.notify_target_reached && truthy?(settings['enable_target_notifications']),
        notify_break_over:     !!@setting.notify_break_over     && truthy?(settings['enable_break_notifications']),
        poll_interval_seconds: poll_interval,
        labels: {
          target_reached: I18n.t(:hm_timeclock_notify_target_reached),
          break_over:     I18n.t(:hm_timeclock_notify_break_over),
          break_required: I18n.t(:label_hm_timeclock_break_required),
          max_daily:      I18n.t(:label_hm_timeclock_max_daily_exceeded)
        }
      }
    end

    private

    def today
      Time.use_zone(@tz) { Time.zone.today }
    end

    def truthy?(v)
      ['1', 1, true, 'true'].include?(v)
    end

    def positive_int(v)
      i = v.to_i
      i.positive? ? i : nil
    end
  end
end
