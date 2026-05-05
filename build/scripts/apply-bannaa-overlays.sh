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

def replace_many(path, replacements)
  text = File.read(path)
  replacements.each do |before, after|
    raise "Pattern not found in #{path}: #{before.inspect}" unless text.include?(before)

    text = text.gsub(before, after)
  end
  File.write(path, text)
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

assets_initializer = File.join(root, "config/initializers/assets.rb")
assets_text = File.read(assets_initializer)
bannaa_asset_version = 'Rails.application.config.assets.version = "1.1-bannaa-20260505"'
unless assets_text.include?(bannaa_asset_version)
  assets_text = assets_text.sub(
    /^Rails\.application\.config\.assets\.version = .+$/,
    bannaa_asset_version,
  )
  File.write(assets_initializer, assets_text)
end

replace_many(
  File.join(root, "app/javascript/onboarding/components/Navigation.jsx"),
  {
    "return 'Finish';" => "return 'إنهاء';",
    "return 'Skip for now';" => "return 'تخطي الآن';",
    "return 'Continue';" => "return 'متابعة';",
    'aria-label="Back to previous onboarding step"' => 'aria-label="الرجوع إلى خطوة الإعداد السابقة"',
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/ProfileForm.jsx"),
  {
    "let errorMessage = 'Unable to continue, please try again.'" => "let errorMessage = 'تعذر المتابعة، حاول مرة أخرى.'",
    "An error occurred: {errorMessage}" => "حدث خطأ: {errorMessage}",
    "Build your profile" => "أكمل ملفك الشخصي",
    "Tell us a little bit about yourself — this is how others\n                will see you on {communityConfig.communityName}. You’ll\n                always be able to edit this later in your Settings." => "أخبرنا قليلًا عن نفسك — هكذا سيراك الآخرون في {communityConfig.communityName}.\n                يمكنك تعديل ذلك لاحقًا من الإعدادات.",
    "label: 'Name'," => "label: 'الاسم',",
    "placeholder_text: 'Your full name'," => "placeholder_text: 'اسمك الكامل',",
    "label: 'Username'," => "label: 'اسم المستخدم',",
    "placeholder_text: 'johndoe'," => "placeholder_text: 'mohammad',",
    "label: 'Bio'," => "label: 'نبذة',",
    "placeholder_text:\n                    'Tell us a little about yourself'," => "placeholder_text:\n                    'اكتب نبذة قصيرة عن نفسك',",
    "Remaining characters:{' '}" => "الأحرف المتبقية:{' '}",
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/ProfileForm/ProfileImage.jsx"),
  {
    "Edit profile image" => "تعديل صورة الملف الشخصي",
    'alt="profile"' => 'alt="الصورة الشخصية"',
    "<Spinner /> Uploading..." => "<Spinner /> جارٍ الرفع...",
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/FollowTags.jsx"),
  {
    "followingStatus = `${selectedTags.length} tag selected`;" => "followingStatus = `تم اختيار وسم واحد`;",
    "followingStatus = `${selectedTags.length} tags selected`;" => "followingStatus = `تم اختيار ${selectedTags.length} وسوم`;",
    "Tags improve your feed. Please leave reactions to further improve your feed. To get started, a \"like\" reaction has been added to the post <strong>{article.title}</strong>. Feel free to undo it later." => "الوسوم تحسن خلاصتك. اترك تفاعلاتك لتحسينها أكثر. للبدء، أضفنا إعجابًا إلى منشور <strong>{article.title}</strong>. يمكنك التراجع عنه لاحقًا.",
    "What are you interested in?" => "ما الذي يهمك؟",
    "Follow tags to customize your feed" => "تابع الوسوم لتخصيص خلاصتك",
    "aria-label={`Follow ${tag.name}`}" => "aria-label={`تابع ${tag.name}`}",
    "? '1 post'\n                            : `${tag.taggings_count} posts`" => "? 'منشور واحد'\n                            : `${tag.taggings_count} منشورات`",
    "Get a Periodic Digest of Top Posts" => "احصل على ملخص دوري لأفضل المنشورات",
    "We'll email you with a curated selection of top posts based on\n                  the tags you follow." => "سنرسل لك بريدًا بملخص مختار من أفضل المنشورات بناءً على\n                  الوسوم التي تتابعها.",
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/FollowUsers.jsx"),
  {
    "followText = `Select ${follows.length}`;" => "followText = `اختيار ${follows.length}`;",
    "followText = `Select all ${follows.length}`;" => "followText = `اختيار الكل ${follows.length}`;",
    "followText = 'Deselect all';" => "followText = 'إلغاء اختيار الكل';",
    "Suggested follows" => "حسابات مقترحة",
    "Kickstart your community" => "ابدأ بناء مجتمعك",
    "aria-label={`Follow ${follow.name}`}" => "aria-label={`تابع ${follow.name}`}",
    "{selected ? 'Following' : 'Follow'}" => "{selected ? 'تتابع' : 'تابع'}",
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/FollowSubforems.jsx"),
  {
    "throw new Error('Failed to fetch subforems');" => "throw new Error('تعذر جلب المجتمعات الفرعية');",
    "console.error('Error fetching subforems:', error);" => "console.error('تعذر جلب المجتمعات الفرعية:', error);",
    "console.error('Error following subforems:', error);" => "console.error('تعذر متابعة المجتمعات الفرعية:', error);",
    "Follow subforems to customize your network" => "تابع المجتمعات لتخصيص شبكتك",
    "Following {count} {count === 1 ? 'subforem' : 'subforems'}" => "{count === 1 ? 'تتابع مجتمعًا واحدًا' : `تتابع ${count} مجتمعات`}",
    "What communities interest you?" => "ما المجتمعات التي تهمك؟",
    "The subforem you joined from is highlighted below. You can follow additional communities to customize your feed." => "المجتمع الذي انضممت منه مميز أدناه. يمكنك متابعة مجتمعات إضافية لتخصيص خلاصتك.",
    "aria-label={`Follow ${subforem.name}`}" => "aria-label={`تابع ${subforem.name}`}",
    "alt={`${subforem.name} logo`}" => "alt={`شعار ${subforem.name}`}",
    "subforem.description || 'Join this community to connect with like-minded people.'" => "subforem.description || 'انضم إلى هذا المجتمع للتواصل مع أشخاص يشاركونك الاهتمامات.'",
    'nextText="Continue"' => 'nextText="متابعة"',
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/EmailPreferencesForm.jsx"),
  {
    "content: '<p>Loading...</p>'," => "content: '<p>جارٍ التحميل...</p>',",
    "👋 One last check" => "مراجعة أخيرة",
    "We Recommend Subscribing to Emails" => "ننصح بتفعيل رسائل البريد",
    "Newsletters are a part of keeping up with the pulse of the overall DEV ecosystem.\n            <span style='display:inline-block'>It's easy to unsubscribe later if it's not for you.</span>" => "النشرات البريدية تساعدك على متابعة أهم ما يحدث في مجتمع Bannaa.\n            <span style='display:inline-block'>يمكنك إلغاء الاشتراك لاحقًا بسهولة إذا لم تكن مناسبة لك.</span>",
    "No thank you" => "لا شكرًا",
    "Count me in" => "أريد الاشتراك",
  },
)

replace_many(
  File.join(root, "app/javascript/onboarding/components/CustomCta.jsx"),
  {
    "console.error('Error submitting custom actions:', error);" => "console.error('تعذر إرسال خيارات المبادرات:', error);",
    "Special Initiatives" => "مبادرات خاصة",
    "DEV offers exclusive events that help you grow as a developer and certify your skills. Follow these special tags to make sure you never miss an update." => "تقدم Bannaa مبادرات وفعاليات تساعدك على تنمية مهاراتك ومتابعة الفرص المهمة. تابع هذه الوسوم حتى لا يفوتك أي تحديث.",
    "Follow DEV Challenges" => "تابع تحديات Bannaa",
    "We offer special coding challenges, hackathons and writing challenges to help you sharpen your skills and win prizes." => "نقدم تحديات كتابة وبرمجة وفعاليات تساعدك على صقل مهاراتك والمنافسة.",
    "Follow DEV Education Tracks" => "تابع مسارات Bannaa التعليمية",
    "Get curated educational content and tutorials on a variety of development topics." => "احصل على محتوى تعليمي مختار وشروحات في موضوعات تطوير متنوعة.",
    "Follow the Google AI Org Account" => "تابع حساب Google AI",
    "We have partnered with Google AI on custom education tracks for upgrading your skills in AI and machine learning." => "نتعاون مع Google AI على مسارات تعليمية تساعدك على تطوير مهاراتك في الذكاء الاصطناعي وتعلم الآلة.",
  },
)

replace_many(
  File.join(root, "app/views/onboardings/_newsletter.html.erb"),
  {
    "<h1>Almost there!</h1>" => "<h1>أوشكت على الانتهاء!</h1>",
    "<p>Review your email preferences before we continue.</p>" => "<p>راجع تفضيلات البريد الإلكتروني قبل المتابعة.</p>",
    '<p class="mt-1 pb-4">I want to receive weekly newsletter emails</p>' => '<p class="mt-1 pb-4">أريد تلقي رسائل النشرة الأسبوعية</p>',
    "Almost there!" => "أوشكت على الانتهاء!",
    "Review your email preferences before we continue." => "راجع تفضيلات البريد الإلكتروني قبل المتابعة.",
    "<legend>Email preferences</legend>" => "<legend>تفضيلات البريد الإلكتروني</legend>",
    'I want to receive weekly newsletter emails.' => 'أريد تلقي رسائل النشرة الأسبوعية.',
    'I want to receive a periodic digest of top posts from my tags.' => 'أريد تلقي ملخص دوري بأفضل المنشورات من الوسوم التي أتابعها.',
  },
)

admin_locale_form = File.join(root, "app/views/admin/settings/forms/_user_experience.html.erb")
if File.exist?(admin_locale_form)
  text = File.read(admin_locale_form)
  unless text.include?('["Arabic", "ar"]')
    text = text.sub('[%w[English en], %w[Français fr]]', '[%w[English en], %w[Français fr], ["Arabic", "ar"]]')
    text = text.sub('["Portuguese", "pt"],', '["Portuguese", "pt"], ["Arabic", "ar"],')
    File.write(admin_locale_form, text)
  end
end

confirmations_new = File.join(root, "app/views/devise/confirmations/new.html.erb")
if File.exist?(confirmations_new)
  replace_once(
    confirmations_new,
    '<% title "Confirm your email" %>',
    '<% title t("views.auth.confirm_email.title") %>'
  )
  replace_once(
    confirmations_new,
    'inline_svg_tag("mail.svg", aria: true, title: "Email", class: "mb-6")',
    'inline_svg_tag("mail.svg", aria: true, title: t("views.auth.confirm_email.icon"), class: "mb-6")'
  )
  replace_once(
    confirmations_new,
    '<h1 class="fs-2xl m:fs-3xl lh-tight fw-bold mb-4">Great! Now confirm your email address.</h1>',
    '<h1 class="fs-2xl m:fs-3xl lh-tight fw-bold mb-4"><%= t("views.auth.confirm_email.heading") %></h1>'
  )
  replace_once(
    confirmations_new,
    <<-'ERB'.chomp,
      <p class="fs-l m:fs-xl color-base-70 m:max-w-50">
        We've sent an email to <span class="fw-bold"><%= proper_email %></span>.
        Click the button inside to confirm your email.</p>
      </p>
    ERB
    <<-'ERB'.chomp
      <p class="fs-l m:fs-xl color-base-70 m:max-w-50">
        <%= t("views.auth.confirm_email.sent_html", email: tag.span(proper_email, class: "fw-bold")) %>
      </p>
    ERB
  )
  replace_once(
    confirmations_new,
    '<button class="color-accent-brand text-underline cursor-pointer js-confirmation-button border-none p-0" role="button">Click here</button> if you didn\'t get the email...',
    '<button class="color-accent-brand text-underline cursor-pointer js-confirmation-button border-none p-0" role="button"><%= t("views.auth.confirm_email.resend_button") %></button> <%= t("views.auth.confirm_email.resend_suffix") %>'
  )
  replace_once(
    confirmations_new,
    'inline_svg_tag("forem-background.svg", aria: true, title: "forem background", class: "forem-background absolute bottom-0 right-0 hidden m:block")',
    'inline_svg_tag("forem-background.svg", aria: true, title: t("views.auth.background"), class: "forem-background absolute bottom-0 right-0 hidden m:block")'
  )
  replace_once(
    confirmations_new,
    '<div>Re-enter the email address below to resend the confirmation link</div>',
    '<div><%= t("views.auth.confirm_email.modal") %></div>'
  )
  replace_once(
    confirmations_new,
    'aria: { label: "Confirmation email address" }',
    'aria: { label: t("views.auth.confirm_email.field_aria_label") }'
  )
  replace_once(
    confirmations_new,
    'f.submit "Resend", role: "button", class: "crayons-btn mr-1"',
    'f.submit t("views.auth.confirm_email.resend"), role: "button", class: "crayons-btn mr-1"'
  )
  replace_once(
    confirmations_new,
    <<-'ERB'.chomp,
        <button class="crayons-btn color-base-70 crayons-btn--ghost js-dismiss-button" role="button">
          Dismiss
        </button>
    ERB
    <<-'ERB'.chomp
        <button class="crayons-btn color-base-70 crayons-btn--ghost js-dismiss-button" role="button">
          <%= t("views.auth.confirm_email.dismiss") %>
        </button>
    ERB
  )
end
RUBY

echo "Applied Bannaa overlays to $FOREM_DIR"
