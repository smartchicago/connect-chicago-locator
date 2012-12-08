class AdminsMailer < ActionMailer::Base
  default from: "no-reply@weconnectchicago.org"

  def signup_notify_admin(admin)
    @admin = admin
    @url  = 'http://locations.weconnectchicago.org/admin/admins?approved=false'
    mail(to: APP_CONFIG['admin1Email'], subject: 'Connect Chicago: New admin registration')
  end

  def notify_approved_admin(admin)
    @admin = admin
    @url  = 'http://locations.weconnectchicago.org/admins/sign_in'
    mail(to: @admin.email, subject: 'Connect Chicago: Your account has been approved')
  end

  def notify_exception exception
    @exception = exception
    mail(to: APP_CONFIG['admin1Email'], subject: '[Exception] #{exception.class}')
  end
end
