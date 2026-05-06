# frozen_string_literal: true

module Bannaa
  module ArabicSearch
    DIACRITICS_REGEX = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]/
    SQL_DIACRITICS_REGEX = "[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]"
    SQL_SOURCE_CHARS = "إأآٱىیئؤةۀکـ"
    SQL_TARGET_CHARS = "اااايييوههك"

    module_function

    def arabic?(value)
      value.to_s.match?(/[\u0600-\u06FF]/)
    end

    def normalize(value)
      value.to_s
        .unicode_normalize(:nfkc)
        .delete("ـ")
        .gsub(DIACRITICS_REGEX, "")
        .tr(SQL_SOURCE_CHARS.delete("ـ"), SQL_TARGET_CHARS)
        .strip
        .gsub(/\s+/, " ")
    end

    def sql_normalize(expression)
      "translate(regexp_replace(lower(coalesce((#{expression})::text, '')), " \
        "'#{SQL_DIACRITICS_REGEX}', '', 'g'), " \
        "'#{SQL_SOURCE_CHARS}', '#{SQL_TARGET_CHARS}')"
    end

    def article_match_sql
      normalized_document = sql_normalize(
        "concat_ws(' ', articles.title, articles.cached_tag_list, articles.body_markdown, " \
          "articles.cached_user_name, articles.cached_user_username, articles.cached_organization)",
      )

      "#{normalized_document} LIKE :bannaa_arabic_search_pattern"
    end

    def comment_match_sql
      normalized_document = sql_normalize("comments.body_markdown")

      "#{normalized_document} LIKE :bannaa_arabic_search_pattern"
    end

    def tag_match_sql
      normalized_document = sql_normalize("tags.name")

      "#{normalized_document} LIKE :bannaa_arabic_search_pattern"
    end

    def user_match_sql
      normalized_document = sql_normalize("concat_ws(' ', users.name, users.username)")

      "#{normalized_document} LIKE :bannaa_arabic_search_pattern"
    end
  end
end
