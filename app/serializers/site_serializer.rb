# frozen_string_literal: true

class SiteSerializer < ApplicationSerializer
  attributes(
    :default_archetype,
    :notification_types,
    :post_types,
    :user_tips,
    :trust_levels,
    :groups,
    :filters,
    :periods,
    :top_menu_items,
    :anonymous_top_menu_items,
    :uncategorized_category_id, # this is hidden so putting it here
    :user_field_max_length,
    :post_action_types,
    :topic_flag_types,
    :can_create_tag,
    :can_tag_topics,
    :can_tag_pms,
    :tags_filter_regexp,
    :top_tags,
    :can_associate_groups,
    :wizard_required,
    :topic_featured_link_allowed_category_ids,
    :user_themes,
    :user_color_schemes,
    :default_dark_color_scheme,
    :censored_regexp,
    :shared_drafts_category_id,
    :custom_emoji_translation,
    :watched_words_replace,
    :watched_words_link,
    :categories,
    :markdown_additional_options,
    :hashtag_configurations,
    :hashtag_icons,
    :displayed_about_plugin_stat_groups,
    :anonymous_default_sidebar_tags,
    :anonymous_sidebar_sections,
    :whispers_allowed_groups_names,
    :denied_emojis,
    :tos_url,
    :privacy_policy_url,
  )

  has_many :archetypes, embed: :objects, serializer: ArchetypeSerializer
  has_many :user_fields, embed: :objects, serializer: UserFieldSerializer
  has_many :auth_providers, embed: :objects, serializer: AuthProviderSerializer

  def user_themes
    cache_fragment("user_themes") do
      Theme
        .where("id = :default OR user_selectable", default: SiteSetting.default_theme_id)
        .order("lower(name)")
        .pluck(:id, :name, :color_scheme_id)
        .map do |id, n, cs|
          {
            theme_id: id,
            name: n,
            default: id == SiteSetting.default_theme_id,
            color_scheme_id: cs,
          }
        end
        .as_json
    end
  end

  def user_color_schemes
    cache_fragment("user_color_schemes") do
      schemes = ColorScheme.includes(:color_scheme_colors).where("user_selectable").order(:name)
      ActiveModel::ArraySerializer.new(
        schemes,
        each_serializer: ColorSchemeSelectableSerializer,
      ).as_json
    end
  end

  def default_dark_color_scheme
    ColorScheme.find_by_id(SiteSetting.default_dark_mode_color_scheme_id).as_json
  end

  def groups
    cache_anon_fragment("group_names") do
      object
        .groups
        .order(:name)
        .select(:id, :name, :flair_icon, :flair_upload_id, :flair_bg_color, :flair_color)
        .map do |g|
          {
            id: g.id,
            name: g.name,
            flair_url: g.flair_url,
            flair_bg_color: g.flair_bg_color,
            flair_color: g.flair_color,
          }
        end
        .as_json
    end
  end

  def post_action_types
    cache_fragment("post_action_types_#{I18n.locale}") do
      types = ordered_flags(PostActionType.types.values)
      ActiveModel::ArraySerializer.new(types).as_json
    end
  end

  def topic_flag_types
    cache_fragment("post_action_flag_types_#{I18n.locale}") do
      types = ordered_flags(PostActionType.topic_flag_types.values)
      ActiveModel::ArraySerializer.new(types, each_serializer: TopicFlagTypeSerializer).as_json
    end
  end

  def default_archetype
    Archetype.default
  end

  def post_types
    Post.types
  end

  def user_tips
    User.user_tips
  end

  def include_user_tips?
    SiteSetting.enable_user_tips
  end

  def filters
    Discourse.filters.map(&:to_s)
  end

  def periods
    TopTopic.periods.map(&:to_s)
  end

  def top_menu_items
    Discourse.top_menu_items.map(&:to_s)
  end

  def anonymous_top_menu_items
    Discourse.anonymous_top_menu_items.map(&:to_s)
  end

  def uncategorized_category_id
    SiteSetting.uncategorized_category_id
  end

  def user_field_max_length
    UserField.max_length
  end

  def can_create_tag
    scope.can_create_tag?
  end

  def can_tag_topics
    scope.can_tag_topics?
  end

  def can_tag_pms
    scope.can_tag_pms?
  end

  def can_associate_groups
    scope.can_associate_groups?
  end

  def include_can_associate_groups?
    scope.is_admin?
  end

  def include_tags_filter_regexp?
    SiteSetting.tagging_enabled
  end

  def tags_filter_regexp
    DiscourseTagging::TAGS_FILTER_REGEXP.source
  end

  def include_top_tags?
    Tag.include_tags?
  end

  def top_tags
    Tag.top_tags(guardian: scope)
  end

  def wizard_required
    true
  end

  def include_wizard_required?
    Wizard.user_requires_completion?(scope.user)
  end

  def include_topic_featured_link_allowed_category_ids?
    SiteSetting.topic_featured_link_enabled
  end

  def topic_featured_link_allowed_category_ids
    scope.topic_featured_link_allowed_category_ids
  end

  def censored_regexp
    WordWatcher.serializable_word_matcher_regexp(:censor, engine: :js)
  end

  def custom_emoji_translation
    Plugin::CustomEmoji.translations
  end

  def shared_drafts_category_id
    SiteSetting.shared_drafts_category.to_i
  end

  def include_shared_drafts_category_id?
    scope.can_see_shared_draft? && SiteSetting.shared_drafts_enabled?
  end

  def watched_words_replace
    WordWatcher.word_matcher_regexps(:replace, engine: :js)
  end

  def watched_words_link
    WordWatcher.word_matcher_regexps(:link, engine: :js)
  end

  def categories
    object.categories.map { |c| c.to_h }
  end

  def markdown_additional_options
    Site.markdown_additional_options
  end

  def hashtag_configurations
    HashtagAutocompleteService.contexts_with_ordered_types
  end

  def hashtag_icons
    HashtagAutocompleteService.data_source_icon_map
  end

  def displayed_about_plugin_stat_groups
    About.displayed_plugin_stat_groups
  end

  def anonymous_default_sidebar_tags
    SiteSetting.default_sidebar_tags.split("|") - DiscourseTagging.hidden_tag_names(scope)
  end

  def include_anonymous_default_sidebar_tags?
    scope.anonymous? && !SiteSetting.legacy_navigation_menu? && SiteSetting.tagging_enabled &&
      SiteSetting.default_sidebar_tags.present?
  end

  def anonymous_sidebar_sections
    SidebarSection
      .public_sections
      .includes(:sidebar_urls)
      .order("(section_type IS NOT NULL) DESC, (public IS TRUE) DESC")
      .map { |section| SidebarSectionSerializer.new(section, root: false) }
  end

  def include_anonymous_sidebar_sections?
    scope.anonymous?
  end

  def whispers_allowed_groups_names
    Group.where(id: SiteSetting.whispers_allowed_groups_map).pluck(:name)
  end

  def include_whispers_allowed_groups_names?
    scope.can_see_whispers?
  end

  def denied_emojis
    @denied_emojis ||= Emoji.denied
  end

  def include_denied_emojis?
    denied_emojis.present?
  end

  def tos_url
    Discourse.tos_url
  end

  def include_tos_url?
    tos_url.present?
  end

  def privacy_policy_url
    Discourse.privacy_policy_url
  end

  def include_privacy_policy_url?
    privacy_policy_url.present?
  end

  private

  def ordered_flags(flags)
    notify_moderators_type = PostActionType.flag_types[:notify_moderators]
    types = flags

    if notify_moderators_flag = types.index(notify_moderators_type)
      types.insert(types.length, types.delete_at(notify_moderators_flag))
    end

    types.map { |id| PostActionType.new(id: id) }
  end
end
