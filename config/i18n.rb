require 'i18n'
require 'i18n/backend/fallbacks'


configure do
  I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
  I18n.load_path += Dir[File.join(settings.root, 'i18n', '*.yml')]
  I18n.backend.load_translations
end


def set_locale(request)
  puts "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
  I18n.locale = extract_locale_from_accept_language_header(request)
  puts "* Locale set to '#{I18n.locale}'"
end
 
def extract_locale_from_accept_language_header(request)
  request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
end

