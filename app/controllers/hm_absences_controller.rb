class HmAbsencesController < ApplicationController
  before_action :require_login
  before_action :find_absence

  helper :hm_timeclock

  def edit
    return unless authorize_edit!
  end

  def update
    return unless authorize_edit!
    attrs = absence_params
    attrs[:status] = HmAbsence::STATUS_REQUESTED unless User.current.admin?
    if @absence.update(attrs)
      flash[:notice] = l(:notice_hm_absence_updated)
      redirect_to redirect_target
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if can_delete?
      @absence.destroy
      flash[:notice] = l(:notice_hm_absence_deleted)
    else
      flash[:error] = l(:notice_hm_absence_forbidden)
    end
    redirect_to redirect_target
  end

  def approve
    return forbidden! unless User.current.admin?
    @absence.update!(status: HmAbsence::STATUS_APPROVED,
                     approved_by_id: User.current.id,
                     approved_at: Time.current)
    flash[:notice] = l(:notice_hm_absence_approved)
    redirect_back(fallback_location: hm_admin_path)
  end

  def reject
    return forbidden! unless User.current.admin?
    @absence.update!(status: HmAbsence::STATUS_REJECTED,
                     approved_by_id: User.current.id,
                     approved_at: Time.current)
    flash[:notice] = l(:notice_hm_absence_rejected)
    redirect_back(fallback_location: hm_admin_path)
  end

  private

  def find_absence
    @absence = HmAbsence.find(params[:id])
  end

  def owner?
    @absence.user_id == User.current.id
  end

  def can_edit?
    User.current.admin? || (owner? && @absence.requested?)
  end

  def can_delete?
    User.current.admin? || (owner? && @absence.requested?)
  end

  def authorize_edit!
    return true if can_edit?
    flash[:error] = l(:notice_hm_absence_forbidden)
    redirect_to redirect_target
    false
  end

  def absence_params
    params.require(:hm_absence).permit(:starts_on, :ends_on, :reason)
  end

  def redirect_target
    case @absence.kind
    when HmAbsence::KIND_VACATION then hm_vacation_path
    when HmAbsence::KIND_SICKNESS then hm_sickness_path
    else hm_timeclock_path
    end
  end

  def forbidden!
    flash[:error] = l(:notice_hm_absence_forbidden)
    redirect_to redirect_target
  end
end
