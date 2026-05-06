class HmTimeclockController < ApplicationController
  before_action :require_login
  before_action :load_user_setting

  helper :hm_timeclock

  def show
    tz = User.current.time_zone || Time.zone
    today = Time.use_zone(tz) { Time.zone.today }
    @today = today
    @month = parse_month_param || today.beginning_of_month
    @entries_today = HmWorkEntry.for_user(User.current).on_day(tz, today).order(:started_at).to_a
    @entries_month = HmWorkEntry.for_user(User.current)
                                .in_range(@month.in_time_zone(tz).beginning_of_day,
                                          @month.end_of_month.in_time_zone(tz).end_of_day)
                                .order(:started_at).to_a
    @snapshot = build_snapshot
  end

  def status
    respond_to do |format|
      format.json { render json: build_snapshot }
    end
  end

  def calendar
    tz = User.current.time_zone || Time.zone
    @month = parse_month_param || Date.current.beginning_of_month
    @entries_month = HmWorkEntry.for_user(User.current)
                                .in_range(@month.in_time_zone(tz).beginning_of_day,
                                          @month.end_of_month.in_time_zone(tz).end_of_day)
                                .order(:started_at).to_a
    respond_to do |format|
      format.html
      format.json { render json: calendar_payload }
    end
  end

  def edit_settings
  end

  def update_settings
    permitted = setting_params
    @user_setting.assign_attributes(permitted)
    if @user_setting.save
      flash[:notice] = l(:notice_hm_timeclock_settings_saved)
      respond_to do |format|
        format.html { redirect_to hm_timeclock_path }
        format.json { render json: build_snapshot }
      end
    else
      respond_to do |format|
        format.html { render :edit_settings }
        format.json { render json: { errors: @user_setting.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def start
    open = current_open_entry
    unless open
      HmWorkEntry.create!(
        user_id:    User.current.id,
        started_at: Time.current,
        state:      HmWorkEntry::STATE_RUNNING,
        created_ip: request.remote_ip
      )
    end
    respond_action(l(:notice_hm_timeclock_started))
  end

  def pause
    entry = current_open_entry
    if entry && entry.running?
      HmWorkEntry.transaction do
        HmBreakEntry.create!(hm_work_entry_id: entry.id, started_at: Time.current)
        entry.update!(state: HmWorkEntry::STATE_PAUSED)
      end
    end
    respond_action(l(:notice_hm_timeclock_paused))
  end

  def resume
    entry = current_open_entry
    if entry && entry.paused?
      HmWorkEntry.transaction do
        brk = entry.current_break
        brk&.update!(ended_at: Time.current)
        entry.update!(state: HmWorkEntry::STATE_RUNNING)
      end
    end
    respond_action(l(:notice_hm_timeclock_resumed))
  end

  def stop
    entry = current_open_entry
    if entry
      HmWorkEntry.transaction do
        brk = entry.current_break
        brk&.update!(ended_at: Time.current)
        entry.update!(state: HmWorkEntry::STATE_COMPLETED, ended_at: Time.current)
      end
    end
    respond_action(l(:notice_hm_timeclock_stopped))
  end

  private

  def load_user_setting
    @user_setting = HmUserSetting.for(User.current)
    @user_setting.save!(validate: false) if @user_setting.new_record?
  end

  def parse_month_param
    return nil unless params[:month].present?
    Date.parse("#{params[:month]}-01")
  rescue ArgumentError
    nil
  end

  def current_open_entry
    HmWorkEntry.for_user(User.current).open.order(started_at: :desc).first
  end

  def respond_action(message)
    respond_to do |format|
      format.html do
        flash[:notice] = message if message.present?
        redirect_to hm_timeclock_path
      end
      format.json { render json: build_snapshot }
    end
  end

  def build_snapshot
    RedmineHmCratchmere::Snapshot.new(User.current, @user_setting).to_h
  end

  def calendar_payload
    tz = User.current.time_zone || Time.zone
    days = (@month..@month.end_of_month).map do |d|
      total = HmWorkEntry.for_user(User.current).on_day(tz, d).to_a.sum { |e| e.net_seconds }
      { date: d.iso8601, seconds: total }
    end
    { month: @month.iso8601, days: days }
  end

  def setting_params
    raw = params[:hm_user_setting] || ActionController::Parameters.new
    raw.permit(:daily_target_minutes, :weekly_target_minutes, :max_break_minutes,
               :notify_target_reached, :notify_break_over)
  end
end
