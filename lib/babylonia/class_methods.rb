require 'yaml'
require 'i18n'

# Let your users translate their content into their languages without additional tables or columns in your tables
# @author Beat Richartz
# @version 0.2.0
# @since 0.0.1
#
module Babylonia
  
  # Helper Methods for locales
  # @author Beat Richartz
  # @version 0.0.2
  # @since 0.0.1
  #
  module HelperMethods
    # Return the currently active locale for the object
    # @return [Symbol] The currently active locale
    #
    def locale
      evaluate_localization_option!(:locale)
    end
    
    # Return the default locale for the object
    # @return [Symbol] The currently active locale
    #
    def default_locale
      evaluate_localization_option!(:default_locale)
    end
    
    # Return if the object falls back on translations
    # @return [Boolean] if the translations fall back to the default locale
    #
    def locale_fallback?
      evaluate_localization_option!(:fallback)
    end
    
    # Return the missing translation placeholder
    # @return [String] The missing translation placeholder
    #
    def missing_translation_placeholder field
      evaluate_localization_option!(:placeholder, field)
    end
    
    # Return if a translation in the language is stored in all translated fields
    # @return [Boolean] True if a translation is stored
    #
    def has_locale? locale
      locales.include?(locale.to_sym)
    end
    
    # Return all the available locales
    # @return [Array] An array of symbols of all available locales
    # 
    def available_locales
      evaluate_localization_option!(:available_locales)
    end
    
    # Return if a locale is theoretically available in all translated fields
    # @return [Boolean] True if the language is available
    #
    def has_available_locale? locale
      available_locales.include?(locale.to_sym)
    end
    
    protected
    
    def translation_nil_or_empty? translation
      translation.nil? or translation.empty?
    end
    
    def dump_translation_locale_hash hash
      YAML.dump(hash.delete_if{|k,v| translation_nil_or_empty?(v) })
    end
    
    def fallback_to_default_locale!(hash, translation, options)
      if translation_nil_or_empty?(translation) and options[:fallback] and locale_fallback?
        hash[default_locale]
      else
        translation
      end
    end
  end
  
  # Method missing implementation for virtual attributes
  # @author Beat Richartz
  # @version 0.0.2
  # @since 0.0.1
  #
  module VirtualAttributes
    # Define method missing to be able to access a language directly
    # Enables to call a language virtual attribute directly
    # @note Since the virtual attribute is called directly, there is no fallback on this unless you set it to true
    # @example Call a getter directly
    #   object.field_de #=> 'DEUTSCH'
    # @example Call a setter directly
    #   object.field_de = 'DEUTSCH'
    # @example Call an untranslated field
    #   object.field_it #=> nil
    #
    # @example Call a field with fallback
    #   object.field_it(fallback: true)
    def method_missing meth, *args, &block
      if parts = extract_locale_method_parts(meth)
        parts[2] ? send(parts[0] + parts[2].to_s, { parts[1].to_sym => args.first }) : send(parts[0], parts[1].to_sym, args.first || {})
      else
        super(meth, *args, &block)
      end
    end
    
    private
    
    def extract_locale_method_parts meth
      if (parts = meth.to_s.match(/\A(\w+)_(\w+)(=)?\z/).to_a[1..3]) && localized?(parts[0]) && has_available_locale?(parts[1])
        parts
      end
    end
  end
  
  # Class methods to extend a class with in order to make it able to handle translatable attributes
  #
  module ClassMethods
    private
    
    def install_locale_field_getter_for(field)
      # Alias method chain the field to a translated value
      # @param [Symbol] locale Pass a locale to get the field translation in this specific locale
      # @param [Boolean] fallback Whether a fallback should be used, defaults to true
      # @return [String, NilClass] Either the string with the translation, the fallback, the placeholder or nil
      # @example Call a field in italian
      #   your_instance.field(:it) #=> "Translation" 
      #
      define_method :"#{field}_translated" do |l=nil, options={fallback: true}|
        field_hash    = send(:"#{field}_hash")
        translation   = field_hash[l || locale]
        translation   = fallback_to_default_locale!(field_hash, translation, options)
        translation_nil_or_empty?(translation) ? missing_translation_placeholder(field) : translation
      end
      alias_method :"#{field}_raw", field
      alias_method field, :"#{field}_translated"
    end
    
    def install_locale_field_hash_for(field)
      # Return the translated values as a hash
      # @return [Hash] The hash with all the translations stored in the field
      #
      define_method :"#{field}_hash" do
        field_content = send(:"#{field}_raw")
        field_content.is_a?(String) ? YAML.load(field_content) : {}
      end
    end
    
    def install_locale_field_setter_for(field)
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
        
        send(:"#{field}_raw=", dump_translation_locale_hash(current_hash))
      end
      alias_method :"#{field}_raw=", :"#{field}="
      alias_method :"#{field}=", :"#{field}_translated="
    end
    
    def install_virtual_locale_attributes_via_method_missing

    end
    
    def install_localized_helper_for(fields)
      # Return if an attribute is localized
      # @return [Boolean] True if the attribute is localized
      # 
      define_method :localized? do |attr|
        fields.include?(attr.to_sym)
      end
    end
    
    def install_locales_helper_for(fields)
      # Return languages stored in all translated fields
      # @return [Array] An array containing all languages stored
      #
      define_method :locales do
        first_field_locales = send(:"#{fields.first}_hash").keys
        fields.inject(first_field_locales){|o, f| o & send(:"#{f}_hash").keys }
      end
    end
    
    def install_locale_options_evaluation(options)
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
    
    def evaluate_locale_options_for(fields)
      options                     = fields.last.is_a?(Hash) ? fields.pop : {}
      options[:locale]            ||= lambda { |r| I18n.locale }
      options[:default_locale]    ||= lambda { |r| I18n.default_locale }
      options[:available_locales] ||= lambda { |r| I18n.available_locales }
      options[:fallback]          = true if options[:fallback].nil?
      options
    end
    
    # Main class method ob Babylonia. Use to make attributes translatable
    # @param [Symbol] fields the attributes to translate
    # @param [Hash] options The options for translation
    # @option [Symbol, Proc, String] locale The current locale - can be either a symbol that will be sent to the instance, a locale symbol that is included in available_locales or a proc that will get called with the instance. Defaults to I18n.locale at the time of use
    # @option [Symbol, Proc, String] default_locale The fallback / default locale - can be either a symbol that will be sent to the instance, a locale symbol that is included in available_locales, a proc that will get called with the instance
    # @option [Symbol, Proc, Array] available_locales The available locales - can be either a symbol that will be sent to the instance, a proc that will get called with the instance, or an Array of symbols of available locales. Defaults to I18n.available_locales at the time of use.
    # @option [Boolean] fallback Wheter to fallback to the default locale or not
    # @option [String] placeholder The placeholder to use for missing translations
    #
    public
    
    def build_babylonian_tower_on(*fields)
      options = evaluate_locale_options_for(fields)
      
      fields.each do |field|
        install_locale_field_getter_for(field)
        install_locale_field_setter_for(field)
        install_locale_field_hash_for(field)
      end
      
      include HelperMethods
      install_localized_helper_for(fields)
      install_locales_helper_for(fields)
      
      include VirtualAttributes
      install_locale_options_evaluation(options)
    end
  end
end