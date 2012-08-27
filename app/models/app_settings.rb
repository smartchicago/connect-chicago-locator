class AppSettings < Settingslogic
  source "#{Rails.root}/config/settings/app_settings.yml"
  namespace Rails.env
end