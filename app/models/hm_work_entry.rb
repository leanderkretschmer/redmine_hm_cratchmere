class HmWorkEntry < ActiveRecord::Base
  self.table_name = 'hm_work_entries'

  STATE_RUNNING   = 'running'.freeze
  STATE_PAUSED    = 'paused'.freeze
  STATE_COMPLETED = 'completed'.freeze
  STATES          = [STATE_RUNNING, STATE_PAUSED, STATE_COMPLETED].freeze

  belongs_to :user
  has_many :hm_break_entries,
           -> { order(:started_at) },
           dependent: :destroy

  validates :started_at, presence: true
  validates :state, inclusion: { in: STATES }

  scope :for_user,  ->(user) { where(user_id: user.is_a?(User) ? user.id : user.to_i) }
  scope :open,      -> { where(state: [STATE_RUNNING, STATE_PAUSED]) }
  scope :completed, -> { where(state: STATE_COMPLETED) }
  scope :on_day, ->(time_zone, day) {
    tz = time_zone || Time.zone
    Time.use_zone(tz) do
      from = day.in_time_zone.beginning_of_day
      to   = day.in_time_zone.end_of_day
      where(started_at: from..to)
    end
  }
  scope :in_range, ->(from, to) { where(started_at: from..to) }

  def open?
    state != STATE_COMPLETED
  end

  def running?
    state == STATE_RUNNING
  end

  def paused?
    state == STATE_PAUSED
  end

  def current_break
    hm_break_entries.detect { |b| b.ended_at.nil? }
  end

  def total_break_seconds(as_of: Time.current)
    hm_break_entries.inject(0) do |sum, b|
      finish = b.ended_at || (open? ? as_of : (ended_at || as_of))
      diff = (finish - b.started_at).to_i
      sum + (diff.positive? ? diff : 0)
    end
  end

  def gross_seconds(as_of: Time.current)
    finish = ended_at || (open? ? as_of : ended_at)
    diff = (finish - started_at).to_i
    diff.positive? ? diff : 0
  end

  def net_seconds(as_of: Time.current)
    [gross_seconds(as_of: as_of) - total_break_seconds(as_of: as_of), 0].max
  end
end
