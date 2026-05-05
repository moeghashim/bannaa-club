#!/usr/bin/env bash
set -euo pipefail

FOREM_DIR="${1:-}"
OVERLAY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/overlays"

if [[ -z "$FOREM_DIR" || ! -d "$FOREM_DIR" ]]; then
  echo "Usage: $0 /path/to/forem" >&2
  exit 1
fi

if [[ ! -f "$FOREM_DIR/Containerfile" || ! -f "$FOREM_DIR/app/controllers/application_controller.rb" ]]; then
  echo "Target does not look like a Forem checkout: $FOREM_DIR" >&2
  exit 1
fi

rsync -a "$OVERLAY_ROOT"/ "$FOREM_DIR"/

FOREM_DIR="$FOREM_DIR" ruby <<'RUBY'
root = ENV.fetch("FOREM_DIR")

def replace_once(path, before, after)
  text = File.read(path)
  raise "Pattern not found in #{path}: #{before.inspect}" unless text.include?(before)

  File.write(path, text.sub(before, after))
end

app_controller = File.join(root, "app/controllers/application_controller.rb")
replace_once(
  app_controller,
  'I18n.locale = if %w[en fr pt].include?(params[:locale])',
  'I18n.locale = if %w[en fr pt ar].include?(params[:locale])'
)

app_helper = File.join(root, "app/helpers/application_helper.rb")
helper_text = File.read(app_helper)
unless helper_text.include?("def rtl_locale?")
  insertion = "\n  def rtl_locale?\n    %i[ar fa he ur].include?(I18n.locale.to_sym)\n  end\n\n"
  helper_text = helper_text.sub(/^end\s*\z/, "#{insertion}end\n")
  File.write(app_helper, helper_text)
end

layout = File.join(root, "app/views/layouts/application.html.erb")
replace_once(
  layout,
  '<html lang="en">',
  '<html lang="<%= I18n.locale %>" dir="<%= rtl_locale? ? "rtl" : "ltr" %>">'
)

layout_text = File.read(layout)
unless layout_text.include?('bannaa_light')
  layout_text = layout_text.sub(
    '<%= render "layouts/styles", qualifier: "main" %>',
    %(<%= render "layouts/styles", qualifier: "main" %>\n      <%= stylesheet_link_tag "bannaa_light", media: "all" %>)
  )
  File.write(layout, layout_text)
end

layout_text = File.read(layout)
unless layout_text.include?('bannaa_rtl')
  layout_text = layout_text.sub(
    '<%= stylesheet_link_tag "bannaa_light", media: "all" %>',
    %(<%= stylesheet_link_tag "bannaa_light", media: "all" %>\n      <%= stylesheet_link_tag "bannaa_rtl", media: "all" if rtl_locale? %>)
  )
  File.write(layout, layout_text)
end

manifest = File.join(root, "app/assets/config/manifest.js")
manifest_text = File.read(manifest)
[
  "//= link bannaa_light.css",
  "//= link bannaa_rtl.css",
  "//= link homePage.js",
  "//= link homePageFeed.js",
  "//= link homePageFeedShortcuts.js"
].each do |line|
  manifest_text << "\n#{line}\n" unless manifest_text.include?(line)
end
File.write(manifest, manifest_text)

admin_locale_form = File.join(root, "app/views/admin/settings/forms/_user_experience.html.erb")
if File.exist?(admin_locale_form)
  text = File.read(admin_locale_form)
  unless text.include?('["Arabic", "ar"]')
    text = text.sub('[%w[English en], %w[Français fr]]', '[%w[English en], %w[Français fr], ["Arabic", "ar"]]')
    text = text.sub('["Portuguese", "pt"],', '["Portuguese", "pt"], ["Arabic", "ar"],')
    File.write(admin_locale_form, text)
  end
end
RUBY

echo "Applied Bannaa overlays to $FOREM_DIR"
