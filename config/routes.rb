RedmineApp::Application.routes.draw do
  scope 'hm_timeclock' do
    get   '',         to: 'hm_timeclock#show',            as: 'hm_timeclock'
    get   'status',   to: 'hm_timeclock#status',          as: 'hm_timeclock_status'
    get   'calendar', to: 'hm_timeclock#calendar',        as: 'hm_timeclock_calendar'
    get   'settings', to: 'hm_timeclock#edit_settings',   as: 'edit_hm_timeclock_settings'
    match 'settings', to: 'hm_timeclock#update_settings', via: [:patch, :put, :post]
    post  'start',    to: 'hm_timeclock#start',           as: 'start_hm_timeclock'
    post  'pause',    to: 'hm_timeclock#pause',           as: 'pause_hm_timeclock'
    post  'resume',   to: 'hm_timeclock#resume',          as: 'resume_hm_timeclock'
    post  'stop',     to: 'hm_timeclock#stop',            as: 'stop_hm_timeclock'
    post  'correct/:id', to: 'hm_timeclock#correct',      as: 'correct_hm_timeclock'
    get   'export',   to: 'hm_timeclock#export',          as: 'export_hm_timeclock'
  end

  get  'hm_vacation', to: 'hm_vacation#show',   as: 'hm_vacation'
  post 'hm_vacation', to: 'hm_vacation#create'
  get  'hm_sickness', to: 'hm_sickness#show',   as: 'hm_sickness'
  post 'hm_sickness', to: 'hm_sickness#create'

  get    'hm_absences/:id/edit',     to: 'hm_absences#edit',    as: 'edit_hm_absence'
  patch  'hm_absences/:id',          to: 'hm_absences#update',  as: 'hm_absence'
  put    'hm_absences/:id',          to: 'hm_absences#update'
  delete 'hm_absences/:id',          to: 'hm_absences#destroy'
  post   'hm_absences/:id/approve',  to: 'hm_absences#approve', as: 'approve_hm_absence'
  post   'hm_absences/:id/reject',   to: 'hm_absences#reject',  as: 'reject_hm_absence'

  scope 'admin/hm_timeclock' do
    get 'day/:date',       to: 'hm_admin#day',   as: 'hm_admin_day',
        constraints: { date: /\d{4}-\d{2}-\d{2}/ }
    get 'users/:user_id',  to: 'hm_admin#show',  as: 'hm_admin_user'
    get '',                to: 'hm_admin#index', as: 'hm_admin'
  end
end
