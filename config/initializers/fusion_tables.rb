#initialize Fusion Tables API
FT = GData::Client::FusionTables.new      
FT.clientlogin(AppSettings.google_account, AppSettings.google_password)