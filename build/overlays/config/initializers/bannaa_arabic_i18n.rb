# Arabic support overlay for Bannaa Club.
#
# Kept small and additive so upstream Forem updates remain straightforward.
Rails.application.config.to_prepare do
  I18n.available_locales = (I18n.available_locales + %i[ar]).uniq
end

Rails.application.config.i18n.fallbacks = [:en] if Rails.application.config.i18n.respond_to?(:fallbacks=)

