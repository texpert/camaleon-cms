module CamaleonCms
  module CustomFieldsRead
    extend ActiveSupport::Concern
    included do
      before_destroy :_destroy_custom_field_groups
    end

    # get custom field groups for current object
    # only: Post_type, Post, Category, PostTag, Widget, Site and a Custom model pre configured
    # return collections CustomFieldGroup
    # args: (Hash, used only for PostType Objects)
    # kind: (Post (Default) | Category | PostTag | PostType).
    # If kind = "Post" this will return all groups for all posts from current post type
    # If kind = "Category" this will return all groups for all categories from current post type
    # If kind = "PostTag" this will return all groups for all posttags from current post type
    # If kind = "all" this will return all groups from current post type
    # If kind = "post_type" this will return groups for all post_types
    # Sample: mypost.get_field_groups() ==> return fields for posts from parent posttype
    # Sample: mycat.get_field_groups() ==> return fields for categories from parent posttype
    # Sample: myposttag.get_field_groups() ==> return fields for posttags from parent posttype
    # Sample: mypost_type.get_field_groups({kind: 'Post'}) => return custom fields for posts
    # Sample: mypost_type.get_field_groups({kind: 'Category'}) => return custom fields for posts
    # Sample: mypost_type.get_field_groups({kind: 'PostTag'}) => return custom fields for posts
    def get_field_groups(args = {})
      args = if args.is_a?(String)
               { kind: args,
                 include_parent: false }
             else
               { kind: 'Post', include_parent: false }.merge!(args)
             end
      class_name = self.class.to_s.parseCamaClass
      case class_name
      when 'Category', 'PostTag'
        post_type.get_field_groups(class_name)
      when 'Post'
        if term_relationships.empty? && args[:cat_ids].nil?
          CamaleonCms::CustomFieldGroup.where(
            '(objectid = ? AND object_class = ?) OR (objectid = ? AND object_class = ?)', id || -1, class_name, post_type.id, "PostType_#{class_name}"
          )
        else
          cat_ids = categories.map(&:id)
          cat_ids += args[:cat_ids] unless args[:cat_ids].nil?
          cat_ids += CamaleonCms::Category.find(cat_ids).map { |category| _category_parents_ids(category) }.flatten.uniq
          CamaleonCms::CustomFieldGroup.where("(objectid = ? AND object_class = ?) OR
                                               (objectid = ? AND object_class = ?) OR
                                               (objectid IN (?) AND object_class = ?)",
                                              id || -1, class_name,
                                              post_type.id, "PostType_#{class_name}",
                                              cat_ids, "Category_#{class_name}")
        end
      when 'NavMenuItem'
        main_menu.custom_field_groups
      when 'PostType'
        case args[:kind]
        when 'all'
          CamaleonCms::CustomFieldGroup.where(object_class: %w[PostType_Post PostType_Post PostType_PostTag PostType],
                                              objectid: id)
        when 'post_type'
          custom_field_groups
        else
          CamaleonCms::CustomFieldGroup.where(object_class: "PostType_#{args[:kind]}", objectid: id)
        end
      else # 'Plugin' or other classes
        custom_field_groups
      end
    end

    # get custom field groups for current user
    # return collections CustomFieldGroup
    # site: site object
    def get_user_field_groups(site)
      site.custom_field_groups.where(object_class: self.class.to_s.parseCamaClass)
    end

    # get custom field value
    # _key: custom field key
    # if value is not present, then return default
    # return default only if the field was not registered
    def get_field_value(_key, _default = nil, group_number = 0)
      v = begin
        get_field_values(_key, group_number).first
      rescue StandardError
        _default
      end
      v.present? ? v : _default
    end
    alias get_field get_field_value
    alias get_field! get_field_value

    # get custom field values
    # _key: custom field key
    def get_field_values(_key, group_number = 0)
      if custom_field_values.loaded?
        custom_field_values.select do |f|
          f.custom_field_slug == _key && f.group_number == group_number
        end.map(&:value)
      else
        custom_field_values.where(custom_field_slug: _key, group_number: group_number).pluck(:value)
      end
    end
    alias get_fields get_field_values

    # return the values of custom fields grouped by group_number
    # field_keys: (array of keys)
    # samples: my_object.get_fields_grouped(['my_slug1', 'my_slug2'])
    #   return: [
    #             { 'my_slug1' => ["val 1"], 'my_slug2' => ['val 2']},
    #             { 'my_slug1' => ["val2 for slug1"], 'my_slug2' => ['val 2 for slug2']}
    #   ] ==> 2 groups
    #
    #   return: [
    #             { 'my_slug1' => ["val 1", 'val 2 for fields multiple support'], 'my_slug2' => ['val 2']},
    #             { 'my_slug1' => ["val2 for slug1", 'val 2'], 'my_slug2' => ['val 2 for slug2']}
    #             { 'my_slug1' => ["val3 for slug1", 'val 3'], 'my_slug2' => ['val 3 for slug2']}
    #   ] ==> 3 groups
    #
    #   puts res[0]['my_slug1'].first ==> "val 1"
    def get_fields_grouped(field_keys)
      res = []
      custom_field_values.where(custom_field_slug: field_keys).order(group_number: :asc).group_by(&:group_number).each_value do |group_fields|
        group = {}
        field_keys.each do |field_key|
          _tmp = []
          group_fields.each { |field| _tmp << field.value if field_key == field.custom_field_slug }
          group[field_key] = _tmp if _tmp.present?
        end
        res << group
      end
      res
    end

    # return all values
    # {key1: "single value", key2: [multiple, values], key3: value4} if include_options = false
    # {key1: {values: "single value", options: {a:1, b: 4}}, key2: {values: [multiple, values], options: {a=1, b=2} }} if include_options = true
    def get_field_values_hash(include_options = false)
      fields = {}
      custom_field_values.to_a.uniq.each do |field_value|
        custom_field = field_value.custom_fields
        values = custom_field.values.where(objectid: id).pluck(:value)
        unless include_options
          fields[field_value.custom_field_slug] =
            custom_field.cama_options[:multiple].to_s.to_bool ? values : values.first
        end
        next unless include_options

        fields[field_value.custom_field_slug] =
          { values: custom_field.cama_options[:multiple].to_s.to_bool ? values : values.first,
            options: custom_field.cama_options, id: custom_field.id }
      end
      fields.to_sym
    end

    # return all custom fields for current element
    # {my_field_slug: {options: {}, values: [], name: '', ...} }
    # deprecated f attribute
    def get_fields_object(_f = true)
      fields = {}
      custom_field_values.eager_load(:custom_fields).to_a.uniq.each do |field_value|
        custom_field = field_value.custom_fields
        # if custom_field.options[:show_frontend].to_s.to_bool
        values = custom_field.values.where(objectid: id).pluck(:value)
        fields[field_value.custom_field_slug] =
          custom_field.attributes.merge(options: custom_field.cama_options,
                                        values: custom_field.cama_options[:multiple].to_s.to_bool ? values : values.first)
        # end
      end
      fields.to_sym
    end

    # add a custom field group for current model
    # values:
    # name: name for the group
    # slug: key for group (if slug = _default => this will never show title and description)
    # description: description for the group (optional)
    # is_repeat: (boolean, optional -> default false) indicate if group support multiple format (repeated values)
    # Model supported: PostType, Category, Post, Posttag, Widget, Plugin, Theme, User and Custom models pre configured
    # Note 1: If you need add fields for all post's or all categories, then you need to add the fields into the
    #     post_type.add_custom_field_group(values, kind = "Post")
    #     post_type.add_custom_field_group(values, kind = "Category")
    # Note 2: If you need add fields for only the Post_type, you have to use options or metas
    # return: CustomFieldGroup object
    # kind: argument only for PostType model: (Post | Category | PostTag), default => Post. If kind = "" this will add group for all post_types
    def add_custom_field_group(values, kind = 'Post')
      values = values.with_indifferent_access
      group = get_field_groups(kind).find_by(slug: values[:slug])
      unless group
        site = _cama_get_field_site
        values[:parent_id] = site.id if site.present?
        group = if is_a?(CamaleonCms::Post) # harcoded for post to support custom field groups
                  CamaleonCms::CustomFieldGroup.where(object_class: 'Post', objectid: id).create!(values)
                else
                  get_field_groups(kind).create!(values)
                end
      end

      group
    end
    alias add_field_group add_custom_field_group

    # Add custom fields for a default group:
    # This will create a new group with slug=_default if it doesn't exist yet
    # more details in add_manual_field(item, options) from custom field groups
    # kind: argument only for PostType model: (Post | Category | PostTag), default => Post
    def add_custom_field_to_default_group(item, options, kind = 'Post')
      g = get_field_groups(kind).find_by(slug: '_default')
      g ||= add_custom_field_group({ name: 'Default Field Group', slug: '_default' }, kind)
      g.add_manual_field(item, options)
    end
    alias add_field add_custom_field_to_default_group

    # return field object for current model
    def get_field_object(slug)
      CamaleonCms::CustomField.where(
        slug: slug,
        parent_id: get_field_groups.pluck(:id)
      ).first || CamaleonCms::CustomField.where(
        slug: slug,
        parent_id: get_field_groups({ include_parent: true })
      ).first
    end

    # save all fields sent from browser (reservated for browser request)
    # sample:
    # {
    #   "0"=>{ "untitled-text-box"=>{"id"=>"262", "values"=>{"0"=>"33333"}}},
    #   "1"=>{ "untitled-text-box"=>{"id"=>"262", "values"=>{"0"=>"33333"}}}
    # }
    def set_field_values(datas = {})
      return unless datas.present?

      ActiveRecord::Base.transaction do
        custom_field_values.delete_all
        datas.each_value do |fields_data|
          fields_data.each do |field_key, values|
            next unless values[:values].present?

            order_value = -1
            (values[:values].is_a?(Hash) || values[:values].is_a?(ActionController::Parameters) ? values[:values].values : values[:values]).each do |value|
              custom_field_values.create!({ custom_field_id: values[:id], custom_field_slug: field_key,
                                            value: fix_meta_value(value), term_order: order_value += 1, group_number: values[:group_number] || 0 })
            end
          end
        end
      end
    end

    # update new value for field with slug _key
    # Sample: my_posy.update_field_value('sub_title', 'Test Sub Title')
    def update_field_value(_key, value = nil, group_number = 0)
      custom_field_values.find_by(custom_field_slug: _key, group_number: group_number)&.update_column('value', value)
    rescue StandardError
      nil
    end

    # Set custom field values for current model
    # key: slug of the custom field
    # value: array of values for multiple values support
    # value: string value
    def save_field_value(key, value, order = 0, clear = true)
      set_field_value(key, value, { clear: clear, order: order })
    end

    # Set custom field values for current model (support for multiple group values)
    # key: (string required) slug of the custom field
    # value: (array | string) array: array of values for multiple values support, string: uniq value for the custom field
    # args:
    #   field_id: (integer optional) identifier of the custom field
    #   order: order or position of the field value
    #   group_number: number of the group (only for custom field group with is_repeat enabled)
    #   clear: (boolean, default true) if true, will remove previous values and set these values, if not will append values
    # return false if the was not saved because there is not present the field with slug: key
    # sample: my_post.set_field_value('subtitle', 'Sub Title')
    # sample: my_post.set_field_value('subtitle', ['Sub Title1', 'Sub Title2']) # set values for a field (for fields that support multiple values)
    # sample: my_post.set_field_value('subtitle', 'Sub Title', {group_number: 1})
    # sample: my_post.set_field_value('subtitle', 'Sub Title', {group_number: 1, group_number: 1}) # add field values for fields in group 1
    def set_field_value(key, value, args = {})
      args = { order: 0, group_number: 0, field_id: nil, clear: true }.merge!(args)
      unless args[:field_id].present?
        args[:field_id] = begin
          get_field_object(key).id
        rescue StandardError
          nil
        end
      end
      raise ArgumentError, "There is no custom field configured for #{key}" unless args[:field_id].present?

      if args[:clear]
        custom_field_values.where({ custom_field_slug: key,
                                    group_number: args[:group_number] }).delete_all
      end
      v = { custom_field_id: args[:field_id], custom_field_slug: key, value: fix_meta_value(value),
            term_order: args[:order], group_number: args[:group_number] }
      if value.is_a?(Array)
        value.each do |val|
          custom_field_values.create!(v.merge({ value: fix_meta_value(val) }))
        end
      else
        custom_field_values.create!(v)
      end
    end

    private

    def fix_meta_value(value)
      return value.to_json if value.is_a?(ActionController::Parameters)
      return JSON.fast_generate(value) if value.is_a?(Array) || value.is_a?(Hash)

      value
    end

    def _destroy_custom_field_groups
      class_name = self.class.to_s.parseCamaClass
      if %w[Category Post PostTag].include?(class_name)
        CamaleonCms::CustomFieldGroup.where(objectid: id, object_class: class_name).destroy_all
      elsif ['PostType'].include?(class_name)
        get_field_groups('Post').destroy_all
        get_field_groups('Category').destroy_all
        get_field_groups('PostTag').destroy_all
      elsif ['NavMenuItem'].include?(class_name) # menu items doesn't include field groups
      elsif get_field_groups.present?
        get_field_groups.destroy_all
      end
    end

    # return the Site Model owner of current model
    def _cama_get_field_site
      case self.class.to_s.parseCamaClass
      when 'Category', 'Post', 'PostTag'
        post_type.site
      when 'Site'
        self
      else
        site
      end
    end

    def _category_parents_ids(category)
      @parents ||= []
      return @parents if category.parent.nil?

      @parents << category.parent.id
      _category_parents_ids(category.parent)
    end
  end
end
