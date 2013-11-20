require 'yaml'
require 'i18n'

# Let your users translate their content into their languages without additional tables or columns in your tables
# @author Beat Richartz
# @version 0.0.2
# @since 0.0.1
#
module Babylonia
  
  # Class methods to extend a class with in order to make it able to handle translatable attributes
  #
  module ClassMethods
    # Main class method ob Babylonia. Use to make attributes translatable
    # @param [Symbol] fields the attributes to translate
    # @param [Hash] options The options for translation
    # @option [Symbol, Proc, String] locale The current locale - can be either a symbol that will be sent to the instance, a locale symbol that is included in available_locales or a proc that will get called with the instance. Defaults to I18n.locale at the time of use
    # @option [Symbol, Proc, String] default_locale The fallback / default locale - can be either a symbol that will be sent to the instance, a locale symbol that is included in available_locales, a proc that will get called with the instance
    # @option [Symbol, Proc, Array] available_locales The available locales - can be either a symbol that will be sent to the instance, a proc that will get called with the instance, or an Array of symbols of available locales. Defaults to I18n.available_locales at the time of use.
    # @option [Boolean] fallback Wheter to fallback to the default locale or not
    # @option [String] placeholder The placeholder to use for missing translations
    #
    def build_babylonian_tower_on(*fields)
      options                     = fields.last.is_a?(Hash) ? fields.pop : {}
      options[:locale]            ||= lambda { |r| I18n.locale }
      options[:default_locale]    ||= lambda { |r| I18n.default_locale }
      options[:available_locales] ||= lambda { |r| I18n.available_locales }
      options[:fallback]          = true if options[:fallback].nil?
      
      fields.each do |field|
        # Alias method chain the field to a translated value
        # @param [Symbol] locale Pass a locale to get the field translation in this specific locale
        # @return [String, NilClass] Either the string with the translation, the fallback, the placeholder or nil
        # @example Call a field in italian
        #   your_instance.field(:it) #=> "Translation" 
        #
        define_method :"#{field}_translated" do |l=nil|
          field_hash    = send(:"#{field}_hash")
          translation   = field_hash[l || locale]
          translation   = field_hash[default_locale] if translation.nil? or translation.empty? and locale_fallback?
          (translation.nil? or translation.empty?) ? missing_translation_placeholder(field) : translation
        end
        alias_method :"#{field}_raw", field
        alias_method field, :"#{field}_translated"
        
        # Return the translated values as a hash
        # @return [Hash] The hash with all the translations stored in the field
        #
        define_method :"#{field}_hash" do
          field_content = send(:"#{field}_raw")
          field_content.is_a?(String) ? YAML.load(field_content) : {}
        end
        
        # Set the field to a value. This either takes a string or a hash
        # If given a String, the current locale is set to this value
        # If given a Hash, the hash is merged into the current translation hash, and empty values are purged
        # @param [String, Hash] data The data to set either the current language translation or all translations to
        # @example Set the translation for the current locale
        #   your_object.field = "TRANSLATION"
        # @example Set the translation and delete italian
        #   your_object.field = {de: 'DEUTSCH', it: ''}
        #
        define_method :"#{field}_translated=" do |data|
          current_hash = send(:"#{field}_hash")
          
          if data.is_a?(String)
            current_hash.merge! locale => data
          elsif data.is_a?(Hash)
            data.delete_if{|k,v| !has_available_locale?(k) }
            current_hash.merge! data
          end
          
          send(:"#{field}_raw=", YAML.dump(current_hash.delete_if{|k,v| v.nil? or v.empty? }))
        end
        alias_method :"#{field}_raw=", :"#{field}="
        alias_method :"#{field}=", :"#{field}_translated="
      end
      
      # Return the currently active locale for the object
      # @return [Symbol] The currently active locale
      #
      define_method :locale do
        evaluate_localization_option!(:locale)
      end
      
      # Return the default locale for the object
      # @return [Symbol] The currently active locale
      #
      define_method :default_locale do
        evaluate_localization_option!(:default_locale)
      end
      
      # Return if the object falls back on translations
      # @return [Boolean] if the translations fall back to the default locale
      #
      define_method :locale_fallback? do
        evaluate_localization_option!(:fallback)
      end
      
      # Return the missing translation placeholder
      # @return [String] The missing translation placeholder
      #
      define_method :missing_translation_placeholder do |field|
        evaluate_localization_option!(:placeholder, field)
      end
      
      # Return languages stored in all translated fields
      # @return [Array] An array containing all languages stored
      #
      define_method :locales do
        first_field_locales = send(:"#{fields.first}_hash").keys
        fields.inject(first_field_locales){|o, f| o & send(:"#{f}_hash").keys }
      end
      
      # Return if a translation in the language is stored in all translated fields
      # @return [Boolean] True if a translation is stored
      #
      define_method :has_locale? do |locale|
        locales.include?(locale.to_sym)
      end
      
      # Return all the available locales
      # @return [Array] An array of symbols of all available locales
      # 
      define_method :available_locales do
        evaluate_localization_option!(:available_locales)
      end
      
      # Return if a locale is theoretically available in all translated fields
      # @return [Boolean] True if the language is available
      #
      define_method :has_available_locale? do |locale|
        available_locales.include?(locale.to_sym)
      end
      
      # Return if an attribute is localized
      # @return [Boolean] True if the attribute is localized
      # 
      define_method :localized? do |attr|
        fields.include?(attr.to_sym)
      end
      
      # Define method missing to be able to access a language directly
      define_method :method_missing do |meth, *args, &block|
        if (m = meth.to_s.match(/\A([^_]+)_(\w+)(=)?\z/).to_a[1..3]) && localized?(m[0]) && has_available_locale?(m[1])
          send(m[0] + m[2].to_s, m[2] ? {m[1].to_sym => args.first} : m[1].to_sym)
        else
          super(meth, *args, &block)
        end
      end
      
      # Evaluate a localization option
      #
      define_method :evaluate_localization_option! do |option, field=nil, recursion=false|
        o = options[option]
        if o.is_a?(Proc) && field
          o.call self, field
        elsif o.is_a?(Proc)
          o.call self
        elsif o.is_a?(Symbol) && (recursion || !evaluate_localization_option!(:available_locales, nil, true).include?(o))
          send o
        else
          o
        end
      end
    end
  end
end