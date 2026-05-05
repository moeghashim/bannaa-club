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
bannaa_stylesheets = %(      <%= stylesheet_link_tag "bannaa_light", media: "all" %>\n      <%= stylesheet_link_tag "bannaa_rtl", media: "all" if rtl_locale? %>)
layout_text = layout_text.gsub(/\n\s*<%= stylesheet_link_tag "bannaa_light", media: "all" %>\n\s*<%= stylesheet_link_tag "bannaa_rtl", media: "all" if rtl_locale\? %>/, "")
body_styles_end = %(      </style>\n      </div>\n      <% if user_signed_in? %>)
if layout_text.include?(body_styles_end)
  layout_text = layout_text.sub(body_styles_end, %(      </style>\n      </div>\n#{bannaa_stylesheets}\n      <% if user_signed_in? %>))
else
  layout_text = layout_text.sub(
    '<%= render "layouts/styles", qualifier: "secondary" %>',
    %(<%= render "layouts/styles", qualifier: "secondary" %>\n#{bannaa_stylesheets})
  )
end
File.write(layout, layout_text)

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
bannaa_asset_version = 'Rails.application.config.assets.version = "1.1-bannaa-20260505-14"'
unless assets_text.include?(bannaa_asset_version)
  assets_text = assets_text.sub(
    /^Rails\.application\.config\.assets\.version = .+$/,
    bannaa_asset_version,
  )
  File.write(assets_initializer, assets_text)
end

replace_once(
  File.join(root, "app/models/article.rb"),
  <<-'RUBY'.chomp,
  pg_search_scope :search_articles,
                  against: :reading_list_document,
                  using: {
                    tsearch: {
                      prefix: true,
                      tsvector_column: :reading_list_document
                    }
                  },
                  ignoring: :accents
  RUBY
  <<-'RUBY'.chomp,
  pg_search_scope :bannaa_pg_search_articles,
                  against: :reading_list_document,
                  using: {
                    tsearch: {
                      prefix: true,
                      tsvector_column: :reading_list_document
                    }
                  },
                  ignoring: :accents

  scope :search_articles, lambda { |term|
    pg_search_relation = bannaa_pg_search_articles(term)
    normalized_term = Bannaa::ArabicSearch.normalize(term)

    if Bannaa::ArabicSearch.arabic?(term) && normalized_term.present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(normalized_term)}%"
      where(
        "#{table_name}.id IN (#{pg_search_relation.unscope(:select).select("#{table_name}.id").to_sql}) OR #{Bannaa::ArabicSearch.article_match_sql}",
        bannaa_arabic_search_pattern: pattern,
      )
    else
      pg_search_relation
    end
  }
  RUBY
)

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

replace_many(
  File.join(root, "app/views/articles/_v2_form.html.erb"),
  {
    'data-text="Edit"' => 'data-text="تحرير"',
    'data-text="Preview"' => 'data-text="معاينة"',
    'alt="Post cover"' => 'alt="غلاف المنشور"',
    "🍌 Generate Image" => "إنشاء صورة",
    '<h3 class="fs-base fw-bold m-0">Editor Guide</h3>' => '<h3 class="fs-base fw-bold m-0">دليل المحرر</h3>',
    'aria-label="Close Editor Guide" title="Close Editor Guide"' => 'aria-label="إغلاق دليل المحرر" title="إغلاق دليل المحرر"',
    'aria-label="Toggle AI Editor Helper" title="Toggle AI Editor Helper"' => 'aria-label="فتح مساعد التحرير الذكي" title="فتح مساعد التحرير الذكي"',
    'aria-label="Close AI Helper" title="Close AI Helper"' => 'aria-label="إغلاق المساعد الذكي" title="إغلاق المساعد الذكي"',
    'BETA' => 'تجريبي',
  },
)

replace_many(
  File.join(root, "app/views/articles/show.html.erb"),
  {
    '<h2 class="crayons-subtitle-2">Boost Post to the Feed</h2>' => '<h2 class="crayons-subtitle-2">تعزيز المنشور في الخلاصة</h2>',
    'aria-label="Close"' => 'aria-label="إغلاق"',
  },
)

replace_many(
  File.join(root, "app/views/articles/_fullscreen_embed.html.erb"),
  {
    '<h2 class="crayons-subtitle-2">Boost Post to the Feed</h2>' => '<h2 class="crayons-subtitle-2">تعزيز المنشور في الخلاصة</h2>',
    'aria-label="Close"' => 'aria-label="إغلاق"',
    "          Moderate\n" => "          إشراف\n",
    "const modTitle = 'Moderation Actions';" => "const modTitle = 'إجراءات الإشراف';",
    'title="Moderation panel actions"' => 'title="إجراءات لوحة الإشراف"',
    'title="Article comments"' => 'title="تعليقات المقال"',
    "const commentsTitle = `Comments${document.querySelector('.js-comments-count') ? ' ' + document.querySelector('.js-comments-count').outerHTML : ''}`;" => "const commentsTitle = `التعليقات${document.querySelector('.js-comments-count') ? ' ' + document.querySelector('.js-comments-count').outerHTML : ''}`;",
  },
)

replace_many(
  File.join(root, "app/views/articles/_actions.html.erb"),
  {
    '<title id="d6cd43ffbad3fe639e2e95c901ee88c8">Moderation</title>' => '<title id="d6cd43ffbad3fe639e2e95c901ee88c8">الإشراف</title>',
    "                Moderate\n" => "                إشراف\n",
  },
)

replace_many(
  File.join(root, "app/views/articles/_multiple_reactions.html.erb"),
  {
    "description: reaction_type.name," => 'description: t("views.reactions.category.#{reaction_type.slug}", default: reaction_type.name),',
    "aria_label: reaction_type.name" => 'aria_label: t("views.reactions.category.#{reaction_type.slug}", default: reaction_type.name)',
  },
)

replace_many(
  File.join(root, "app/views/articles/_multiple_engagements.html.erb"),
  {
    'aria-label="<%= reaction_type.name %>"' => 'aria-label="<%= t("views.reactions.category.#{reaction_type.slug}", default: reaction_type.name) %>"',
  },
)

replace_many(
  File.join(root, "app/assets/javascripts/initializers/initializeBaseUserData.js"),
  {
    'rel="nofollow">Edit</a>`' => 'rel="nofollow">تحرير</a>`',
    'rel="nofollow">Manage</a>`' => 'rel="nofollow">إدارة</a>`',
    'rel="nofollow">Stats</a>`' => 'rel="nofollow">الإحصاءات</a>`',
    'data-no-instant>Admin</a>`' => 'data-no-instant>المدير</a>`',
    '" class="crayons-link crayons-link--block" data-no-instant>Settings</a>\';' => '" class="crayons-link crayons-link--block" data-no-instant>الإعدادات</a>\';',
    '" rel="nofollow" class="crayons-link crayons-link--block">Moderate</a>\';' => '" rel="nofollow" class="crayons-link crayons-link--block">إشراف</a>\';',
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Tabs.jsx"),
  {
    'aria-label="View post modes"' => 'aria-label="أوضاع عرض المنشور"',
    'data-text="Edit"' => 'data-text="تحرير"',
    'data-text="Preview"' => 'data-text="معاينة"',
    "\n            Edit\n" => "\n            تحرير\n",
    "\n            Preview\n" => "\n            معاينة\n",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/PageTitle.jsx"),
  {
    "{previewLoading ? 'Loading preview' : 'Create Post'}" => "{previewLoading ? 'جارٍ تحميل المعاينة' : 'إنشاء منشور'}",
    'emptyLabel="Personal"' => 'emptyLabel="شخصي"',
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Close.jsx"),
  {
    'title="Close the editor"' => 'title="إغلاق المحرر"',
    'aria-label="Close the editor"' => 'aria-label="إغلاق المحرر"',
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Toolbar.jsx"),
  {
    'title="Upload Agent Session"' => 'title="رفع جلسة الوكيل"',
    'aria-label="Upload Agent Session"' => 'aria-label="رفع جلسة الوكيل"',
    "\n            Agent Session\n" => "\n            جلسة الوكيل\n",
    'aria-label="Help"' => 'aria-label="مساعدة"',
    'title="Help"' => 'title="مساعدة"',
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/ArticleCoverImage.jsx"),
  {
    "Add Cover Image" => "إضافة صورة غلاف",
    'aria-label="Close"' => 'aria-label="إغلاق"',
    "Upload Image" => "رفع صورة",
    "🍌 Generate Image" => "إنشاء صورة",
    "`Use a ratio of 1000:${coverImageHeight} `" => "`استخدم نسبة 1000:${coverImageHeight} `",
    "'Minimum 1000px wide '" => "'الحد الأدنى للعرض 1000 بكسل '",
    "for best results." => "لأفضل نتيجة.",
    "Generate Cover Image with Instructions 🍌" => "إنشاء صورة غلاف بتعليمات",
    "Describe the image you want to generate. Be as specific as you want, or just go with vibes." => "صف الصورة التي تريد إنشاءها. يمكنك أن تكون محددًا قدر ما تريد.",
    "Image Description" => "وصف الصورة",
    'placeholder="Example: A futuristic cityscape at sunset with flying cars and neon lights"' => 'placeholder="مثال: مدينة مستقبلية عند الغروب مع أضواء نيون"',
    "<Spinner /> Generating..." => "<Spinner /> جارٍ الإنشاء...",
    "'Generate Image'" => "'إنشاء صورة'",
    "Cancel" => "إلغاء",
    "Curious how this works? The Forem codebase is" => "هل تريد معرفة كيف يعمل هذا؟ قاعدة Forem البرمجية",
    "open source 🍌" => "مفتوحة المصدر",
    "const uploadLabel = mainImage ? 'Change' : 'Upload Cover Image';" => "const uploadLabel = mainImage ? 'تغيير' : 'رفع صورة الغلاف';",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/CoverVideoLink.jsx"),
  {
    "Please enter a valid YouTube, Mux, or Twitch video URL." => "أدخل رابط فيديو صالحًا من YouTube أو Mux أو Twitch.",
    "Add Cover Video Link" => "إضافة رابط فيديو الغلاف",
    'aria-label="Close"' => 'aria-label="إغلاق"',
    "Enter a YouTube, Mux, or Twitch video URL to use as the cover video for your article." => "أدخل رابط فيديو من YouTube أو Mux أو Twitch لاستخدامه كفيديو غلاف للمقال.",
    "Video URL" => "رابط الفيديو",
    "Supported formats:" => "الصيغ المدعومة:",
    "*only direct video links, not channel stream" => "*روابط الفيديو المباشرة فقط، وليس بث القناة",
    "{currentUrl ? 'Update Link' : 'Add Link'}" => "{currentUrl ? 'تحديث الرابط' : 'إضافة الرابط'}",
    "Cancel" => "إلغاء",
    "Remove" => "إزالة",
    "{videoSourceUrl ? 'Change Video Link' : 'Cover Video Link'}" => "{videoSourceUrl ? 'تغيير رابط الفيديو' : 'رابط فيديو الغلاف'}",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/TagsField.jsx"),
  {
    "Top tags" => "أبرز الوسوم",
  },
)

replace_many(
  File.join(root, "app/javascript/crayons/MultiSelectAutocomplete/MultiSelectAutocomplete.jsx"),
  {
    "`Maximum ${maxSelections} selections`" => "`${maxSelections} اختيارات كحد أقصى`",
    "<p>Selected items:</p>" => "<p>العناصر المحددة:</p>",
    "`Only ${maxSelections} ${maxSelections == 1 ? 'selection' : 'selections'} allowed`" => "`${maxSelections} اختيارات مسموحة كحد أقصى`",
  },
)

replace_many(
  File.join(root, "app/javascript/crayons/MultiSelectAutocomplete/TagAutocompleteSelection.jsx"),
  {
    "aria-label={`Edit ${name}`}" => "aria-label={`تحرير ${name}`}",
    "aria-label={`Remove ${name}`}" => "aria-label={`إزالة ${name}`}",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Help/ArticleFormTitle.jsx"),
  {
    "Writing a Great Post Title" => "كتابة عنوان منشور جيد",
    "Think of your post title as a super short (but compelling!) description\n        — like an overview of the actual post in one short sentence." => "تعامل مع عنوان المنشور كوصف قصير وجذاب يلخص فكرة المنشور في جملة واحدة.",
    "Use keywords where appropriate to help ensure people can find your post\n        by search." => "استخدم الكلمات المفتاحية المناسبة حتى يسهل العثور على منشورك في البحث.",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Help/TagInput.jsx"),
  {
    "Tagging Guidelines" => "إرشادات الوسوم",
    "Tags help people find your post - think of them as the topics or\n        categories that best describe your post." => "تساعد الوسوم الناس على العثور على منشورك، وهي الموضوعات أو التصنيفات التي تصف المنشور.",
    "Add up to four comma-separated tags per post. Use existing tags whenever\n        possible." => "أضف حتى أربعة وسوم لكل منشور. استخدم الوسوم الموجودة كلما أمكن.",
    "Some tags have special posting guidelines - double check to make sure\n        your post complies with them." => "لبعض الوسوم إرشادات نشر خاصة، تحقق من توافق منشورك معها.",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Help/ArticleTips.jsx"),
  {
    "Publishing Tips" => "نصائح النشر",
    "Ensure your post has a cover image set to make the most of the home feed\n        and social media platforms." => "أضف صورة غلاف للمنشور ليظهر بشكل أفضل في الخلاصة ومنصات التواصل.",
    "Share your post on social media platforms or with your co-workers or\n        local communities." => "شارك منشورك على منصات التواصل أو مع زملائك أو مجتمعاتك المحلية.",
    "Ask people to leave questions for you in the comments. It's a great way\n        to spark additional discussion describing personally why you wrote it or\n        why people might find it helpful." => "اطلب من الناس ترك أسئلتهم في التعليقات لفتح نقاش إضافي حول سبب كتابتك للمنشور وفائدته.",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Help/EditorFormattingHelp.jsx"),
  {
    "Editor Basics" => "أساسيات المحرر",
    "to write and format posts." => "لكتابة المنشورات وتنسيقها.",
    "Commonly used syntax" => "صيغ شائعة الاستخدام",
    "Embed rich content such as Tweets, YouTube videos, etc. Use the complete\n        URL:" => "ضمّن محتوى غنيًا مثل التغريدات أو فيديوهات YouTube وغيرها. استخدم الرابط الكامل:",
    "See a list of supported embeds" => "عرض قائمة التضمينات المدعومة",
    "In addition to images for the post's content, you can also drag and drop\n        a cover image." => "بالإضافة إلى صور محتوى المنشور، يمكنك سحب وإفلات صورة غلاف.",
    "Embed coding agent sessions from Claude Code, Codex, Gemini CLI, and\n        more:" => "ضمّن جلسات وكلاء البرمجة من Claude Code وCodex وGemini CLI وغيرها:",
    "different parts throughout your post:" => "أجزاء مختلفة داخل منشورك:",
    "Upload a session" => "رفع جلسة",
  },
)

replace_many(
  File.join(root, "app/javascript/crayons/MarkdownToolbar/markdownSyntaxFormatters.jsx"),
  {
    "label: 'Bold'," => "label: 'غامق',",
    "label: 'Italic'," => "label: 'مائل',",
    "label: 'Link'," => "label: 'رابط',",
    "label: 'Ordered list'," => "label: 'قائمة مرقمة',",
    "label: 'Unordered list'," => "label: 'قائمة نقطية',",
    "label: 'Heading'," => "label: 'عنوان',",
    "label: 'Quote'," => "label: 'اقتباس',",
    "label: 'Code'," => "label: 'كود',",
    "label: 'Code block'," => "label: 'كتلة كود',",
    "label: 'Embed'," => "label: 'تضمين',",
    "label: 'Underline'," => "label: 'تسطير',",
    "label: 'Strikethrough'," => "label: 'يتوسطه خط',",
    "label: 'Line divider'," => "label: 'فاصل',",
  },
)

replace_many(
  File.join(root, "app/javascript/crayons/MarkdownToolbar/MarkdownToolbar.jsx"),
  {
    '<span aria-hidden="true">Upload image</span>' => '<span aria-hidden="true">رفع صورة</span>',
    'aria-label="More options"' => 'aria-label="خيارات أكثر"',
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/ImageUploader.jsx"),
  {
    'aria-label="Upload an image"' => 'aria-label="رفع صورة"',
    'aria-label="Upload image"' => 'aria-label="رفع صورة"',
    'aria-label="Cancel image upload"' => 'aria-label="إلغاء رفع الصورة"',
    'tooltip="Cancel upload"' => 'tooltip="إلغاء الرفع"',
    "<Spinner /> Uploading..." => "<Spinner /> جارٍ الرفع...",
    "Upload image" => "رفع صورة",
    "image\n            <input" => "\n            <input",
    "`![Image description](${response.links})`" => "`![وصف الصورة](${response.links})`",
    "'image upload complete'" => "'اكتمل رفع الصورة'",
    "`![Image description](${message.link})`" => "`![وصف الصورة](${message.link})`",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/EditorActions.jsx"),
  {
    "? 'Publishing...'\n            : `Saving ${isVersion2 ? 'post' : ''}...`" => "? 'جارٍ النشر...'\n            : `جارٍ حفظ ${isVersion2 ? 'المنشور' : ''}...`",
    "Save <span className=\"hidden s:inline\">Draft</span>" => "حفظ <span className=\"hidden s:inline\">كمسودة</span>",
    "⏰ Scheduled" => "⏰ مجدول",
    "🔗 Canonical" => "🔗 الرابط الأصلي",
    "title={`Series: ${series}`}" => "title={`سلسلة: ${series}`}",
    "Revert <span className=\"hidden s:inline\">new changes</span>" => "التراجع عن <span className=\"hidden s:inline\">التغييرات الجديدة</span>",
  },
)

replace_many(
  File.join(root, "app/javascript/CommentSubscription/CommentSubscription.jsx"),
  {
    '<title id="ai2ols8ka2ohfp0z568lj68ic2du21s">Preferences</title>' => '<title id="ai2ols8ka2ohfp0z568lj68ic2du21s">التفضيلات</title>',
    'labelText="Comment subscription options"' => 'labelText="خيارات الاشتراك في التعليقات"',
    "{subscribed ? 'Unsubscribe' : 'Subscribe'}" => "{subscribed ? 'إلغاء الاشتراك' : 'اشتراك'}",
    "All comments" => "كل التعليقات",
    "You’ll receive notifications for all new comments." => "ستتلقى تنبيهات لكل التعليقات الجديدة.",
    "Top-level comments" => "التعليقات الرئيسية",
    "You’ll receive notifications only for all new top-level\n                    comments." => "ستتلقى تنبيهات للتعليقات الرئيسية الجديدة فقط.",
    "Post author comments" => "تعليقات كاتب المنشور",
    "You’ll receive notifications only if post author sends a new\n                    comment." => "ستتلقى تنبيهات فقط عندما يضيف كاتب المنشور تعليقًا جديدًا.",
    "\n              Done\n" => "\n              تم\n",
  },
)

replace_many(
  File.join(root, "app/javascript/packs/subscribeButton.js"),
  {
    "const verb = subscriptionIsActive ? 'Subscribed' : 'Subscribe';" => "const verb = subscriptionIsActive ? 'مشترك' : 'اشترك';",
    "noun = 'thread';" => "noun = 'السلسلة';",
    "label = `${verb} to top-level comments`;" => "label = subscriptionIsActive ? 'مشترك في التعليقات الرئيسية' : 'اشترك في التعليقات الرئيسية';",
    "mobileLabel = `Top-level ${noun}`;" => "mobileLabel = 'التعليقات الرئيسية';",
    "label = `${verb} to author comments`;" => "label = subscriptionIsActive ? 'مشترك في تعليقات الكاتب' : 'اشترك في تعليقات الكاتب';",
    "mobileLabel = `Author ${noun}`;" => "mobileLabel = 'تعليقات الكاتب';",
    "label = `${verb} to ${noun}`;" => "label = subscriptionIsActive ? `مشترك في ${noun}` : `اشترك في ${noun}`;",
    "mobileLabel = `${noun}`.charAt(0).toUpperCase() + noun.slice(1);" => "mobileLabel = noun;",
    "let noun = 'comments';" => "let noun = 'التعليقات';",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/Options.jsx"),
  {
    "Convert to a Draft" => "تحويل إلى مسودة",
    "Danger Zone" => "منطقة حساسة",
    "Unpublish post" => "إلغاء نشر المنشور",
    "Schedule Publication" => "جدولة النشر",
    "Set a date and time to publish your post in the future. Leave empty to publish immediately." => "حدد تاريخًا ووقتًا لنشر المنشور لاحقًا. اتركه فارغًا للنشر فورًا.",
    "\n              Date\n" => "\n              التاريخ\n",
    'aria-label="Schedule publication date"' => 'aria-label="تاريخ النشر المجدول"',
    "\n              Time\n" => "\n              الوقت\n",
    'aria-label="Schedule publication time"' => 'aria-label="وقت النشر المجدول"',
    "<strong>Post will be published:</strong>" => "<strong>سيتم نشر المنشور:</strong>",
    "Using your local timezone:" => "باستخدام منطقتك الزمنية المحلية:",
    "Current time:" => "الوقت الحالي:",
    "Clear schedule" => "مسح الجدولة",
    'title="Advanced Post options"' => 'title="خيارات المنشور المتقدمة"',
    'aria-label="Advanced Post options"' => 'aria-label="خيارات المنشور المتقدمة"',
    "Advanced Options" => "خيارات متقدمة",
    'title="Advanced Post Options"' => 'title="خيارات المنشور المتقدمة"',
    "Canonical URL" => "الرابط الأصلي",
    "Change meta tag <code>canonical_url</code> if this post was first published elsewhere (like your own blog)." => "غيّر وسم <code>canonical_url</code> إذا كان هذا المنشور منشورًا أولًا في مكان آخر، مثل مدونتك.",
    "\n                  Series\n" => "\n                  سلسلة\n",
    "Organize your posts into a series for better discoverability." => "نظم منشوراتك ضمن سلسلة لتسهيل اكتشافها.",
    "Done" => "تم",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/articleForm.jsx"),
  {
    'aria-label="Edit post"' => 'aria-label="تحرير المنشور"',
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/SeriesSelectorModal.jsx"),
  {
    'title="Manage Series"' => 'title="إدارة السلاسل"',
    "Select an existing series" => "اختر سلسلة موجودة",
    "Personal" => "شخصي",
    "Create new series" => "إنشاء سلسلة جديدة",
    "Give your series a unique name. The series will be visible once it has multiple posts." => "اختر اسمًا فريدًا للسلسلة. ستظهر السلسلة عندما تحتوي على أكثر من منشور.",
    "<strong>Currently selected:</strong>" => "<strong>المحدد حاليًا:</strong>",
    "Remove series" => "إزالة السلسلة",
    "Create a new series" => "إنشاء سلسلة جديدة",
    "Series name" => "اسم السلسلة",
    'placeholder="Enter series name..."' => 'placeholder="أدخل اسم السلسلة..."',
    "Create series" => "إنشاء السلسلة",
    "Cancel" => "إلغاء",
  },
)

replace_many(
  File.join(root, "app/javascript/article-form/components/SeriesSelector.jsx"),
  {
    "Select an existing series" => "اختر سلسلة موجودة",
    "Create new series" => "إنشاء سلسلة جديدة",
    "Give your series a unique name. The series will be visible once it has multiple posts." => "اختر اسمًا فريدًا للسلسلة. ستظهر السلسلة عندما تحتوي على أكثر من منشور.",
    "<strong>Currently selected:</strong>" => "<strong>المحدد حاليًا:</strong>",
    "Remove series" => "إزالة السلسلة",
    "Create a new series" => "إنشاء سلسلة جديدة",
    "Series name" => "اسم السلسلة",
    'placeholder="Enter series name..."' => 'placeholder="أدخل اسم السلسلة..."',
    "{isCreating ? 'Creating...' : 'Create series'}" => "{isCreating ? 'جارٍ الإنشاء...' : 'إنشاء السلسلة'}",
    "Cancel" => "إلغاء",
  },
)

replace_many(
  File.join(root, "app/views/comments/settings.html.erb"),
  {
    'f.submit "Unsubscribe from parent post", class: "crayons-btn crayons-btn--secondary"' => 'f.submit t("views.comments.settings.subscribe.unsubscribe_parent"), class: "crayons-btn crayons-btn--secondary"',
  },
)

replace_many(
  File.join(root, "app/views/comments/edit.html.erb"),
  {
    '<% title "Editing Comment" %>' => '<% title t("views.comments.edit") %>',
  },
)

replace_many(
  File.join(root, "app/views/articles/manage.html.erb"),
  {
    '<h3 class="manage-sidebar-title">Sections</h3>' => '<h3 class="manage-sidebar-title">الأقسام</h3>',
    ">Overview</a>" => ">نظرة عامة</a>",
    ">Statistics</a>" => ">الإحصاءات</a>",
    ">Edit Post</a>" => ">تحرير المنشور</a>",
    ">Pin to Profile</a>" => ">تثبيت في الملف الشخصي</a>",
    ">Discussion Lock</a>" => ">قفل النقاش</a>",
    ">Delete Post</a>" => ">حذف المنشور</a>",
    ">Tips</a>" => ">نصائح</a>",
    '<h2 class="crayons-title mb-4">Post Overview</h2>' => '<h2 class="crayons-title mb-4">نظرة عامة على المنشور</h2>',
    "Series: <%= @article.series %>" => "السلسلة: <%= @article.series %>",
    "\n          Published <%= tag.time(@article.readable_publish_date, datetime: @article.published_timestamp) %>" => "\n          نُشر <%= tag.time(@article.readable_publish_date, datetime: @article.published_timestamp) %>",
    "· Edited <%= tag.time(@article.readable_edit_date, datetime: @article.edited_at.utc.iso8601) %>" => "· حُرر <%= tag.time(@article.readable_edit_date, datetime: @article.edited_at.utc.iso8601) %>",
    "<strong>Draft</strong> - This post is not published yet." => "<strong>مسودة</strong> - لم يتم نشر هذا المنشور بعد.",
    "<h4 class=\"mb-2 fw-bold\">Organization Admin: Change Author</h4>" => "<h4 class=\"mb-2 fw-bold\">إدارة المنظمة: تغيير الكاتب</h4>",
    '<label class="mb-0">Author:</label>' => '<label class="mb-0">الكاتب:</label>',
    'f.submit "Update Author", class: "crayons-btn crayons-btn--secondary"' => 'f.submit "تحديث الكاتب", class: "crayons-btn crayons-btn--secondary"',
    '<h2 class="crayons-title mb-0">Statistics</h2>' => '<h2 class="crayons-title mb-0">الإحصاءات</h2>',
    ">View Detailed Stats</a>" => ">عرض الإحصاءات التفصيلية</a>",
    ">Page Views</div>" => ">مشاهدات الصفحة</div>",
    ">Reactions</div>" => ">التفاعلات</div>",
    ">Comments</div>" => ">التعليقات</div>",
    '<h2 class="crayons-title mb-2">Edit Post</h2>' => '<h2 class="crayons-title mb-2">تحرير المنشور</h2>',
    "Make changes to your post content, title, tags, or cover image." => "عدّل محتوى المنشور أو عنوانه أو وسومه أو صورة الغلاف.",
    '<h2 class="crayons-title mb-2">Pin to Profile</h2>' => '<h2 class="crayons-title mb-2">تثبيت في الملف الشخصي</h2>',
    "Pinning a post to your profile makes it appear at the top of your profile page. You can pin up to 5 posts to highlight your best work." => "تثبيت منشور في ملفك الشخصي يجعله يظهر أعلى الصفحة. يمكنك تثبيت حتى 5 منشورات لإبراز أفضل أعمالك.",
    "\n            Unpin from Profile\n" => "\n            إلغاء التثبيت من الملف الشخصي\n",
    "This post is currently pinned to your profile." => "هذا المنشور مثبت حاليًا في ملفك الشخصي.",
    "\n            Pin to Profile\n" => "\n            تثبيت في الملف الشخصي\n",
    '<h2 class="crayons-title mb-2">Discussion Lock</h2>' => '<h2 class="crayons-title mb-2">قفل النقاش</h2>',
    "Locking the discussion prevents new comments from being posted. Existing comments will remain visible. This is useful if you want to close the conversation on your article." => "قفل النقاش يمنع إضافة تعليقات جديدة. ستبقى التعليقات الحالية ظاهرة. هذا مفيد إذا أردت إغلاق النقاش على مقالك.",
    "\n          Unlock Discussion\n" => "\n          فتح النقاش\n",
    "Discussion is currently locked. No new comments can be posted." => "النقاش مقفل حاليًا. لا يمكن إضافة تعليقات جديدة.",
    "\n          Lock Discussion\n" => "\n          قفل النقاش\n",
    '<h2 class="crayons-title mb-2">Delete Post</h2>' => '<h2 class="crayons-title mb-2">حذف المنشور</h2>',
    "<strong>Recommendation:</strong> Instead of deleting, consider unpublishing your post. This keeps your content and its history while removing it from public view. You can always republish it later." => "<strong>توصية:</strong> بدلًا من الحذف، يمكنك إلغاء نشر المنشور. هذا يحافظ على المحتوى وتاريخه مع إزالته من العرض العام. يمكنك إعادة نشره لاحقًا.",
    "<strong>Warning:</strong> Deleting your post is permanent and cannot be undone. All comments, reactions, and statistics will be lost." => "<strong>تحذير:</strong> حذف المنشور دائم ولا يمكن التراجع عنه. ستفقد كل التعليقات والتفاعلات والإحصاءات.",
    "\n          Delete Post\n" => "\n          حذف المنشور\n",
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
