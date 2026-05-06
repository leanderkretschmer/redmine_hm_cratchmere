class HmAbsence < ActiveRecord::Base
  self.table_name = 'hm_absences'

  KIND_VACATION = 'vacation'.freeze
  KIND_SICKNESS = 'sickness'.freeze
  KINDS         = [KIND_VACATION, KIND_SICKNESS].freeze

  STATUS_REQUESTED = 'requested'.freeze
  STATUS_APPROVED  = 'approved'.freeze
  STATUS_REJECTED  = 'rejected'.freeze
  STATUSES         = [STATUS_REQUESTED, STATUS_APPROVED, STATUS_REJECTED].freeze

  belongs_to :user
  belongs_to :approver, class_name: 'User', foreign_key: 'approved_by_id', optional: true

  validates :kind,   inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :starts_on, :ends_on, presence: true
  validate  :ends_after_starts

  scope :for_user,  ->(u) { where(user_id: u.is_a?(User) ? u.id : u.to_i) }
  scope :vacation,  -> { where(kind: KIND_VACATION) }
  scope :sickness,  -> { where(kind: KIND_SICKNESS) }
  scope :pending,   -> { where(status: STATUS_REQUESTED) }
  scope :approved,  -> { where(status: STATUS_APPROVED) }
  scope :rejected,  -> { where(status: STATUS_REJECTED) }
  scope :active,    -> { where(status: [STATUS_REQUESTED, STATUS_APPROVED]) }
  scope :overlapping, ->(from, to) { where('starts_on <= ? AND ends_on >= ?', to, from) }

  def vacation?;  kind == KIND_VACATION; end
  def sickness?;  kind == KIND_SICKNESS; end
  def requested?; status == STATUS_REQUESTED; end
  def approved?;  status == STATUS_APPROVED; end
  def rejected?;  status == STATUS_REJECTED; end
  def pending?;   requested?; end

  def days
    return 0 if starts_on.blank? || ends_on.blank?
    (ends_on - starts_on).to_i + 1
  end

  def includes_date?(date)
    starts_on <= date && date <= ends_on
  end

  def self.kind_label(kind)
    case kind
    when KIND_VACATION then I18n.t(:label_hm_hr_vacation)
    when KIND_SICKNESS then I18n.t(:label_hm_hr_sickness)
    else kind.to_s.humanize
    end
  end

  def self.status_label(status)
    case status
    when STATUS_REQUESTED then I18n.t(:label_hm_absence_status_requested)
    when STATUS_APPROVED  then I18n.t(:label_hm_absence_status_approved)
    when STATUS_REJECTED  then I18n.t(:label_hm_absence_status_rejected)
    else status.to_s.humanize
    end
  end

  def self.build_by_day(absences, range_from, range_to)
    result = Hash.new { |h, k| h[k] = [] }
    absences.each do |a|
      from = [a.starts_on, range_from].max
      to   = [a.ends_on,   range_to].min
      next if from > to
      (from..to).each { |d| result[d] << a }
    end
    result
  end

  private

  def ends_after_starts
    return if starts_on.blank? || ends_on.blank?
    errors.add(:ends_on, :greater_than_or_equal_to) if ends_on < starts_on
  end
end
