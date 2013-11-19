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
    # @option [Symbol, Proc, String] locale The current locale - can be either a symbol that will be sent to the instance, a proc that will get called with the instance and the attribute name, or a string that will get symbolized as a constant locale. Defaults to I18n.locale at the time of use
    # @option [Symbol, Proc, String] default_locale The fallback / default locale - can be either a symbol that will be sent to the instance, a proc that will get called with the instance and the attribute name, or a string that will get symbolized as a constant locale. Defaults to I18n.default_locale
    # @option [Boolean] fallback Wheter to fallback to the default locale or not
    # @option [String] placeholder The placeholder to use for missing translations
    #
    def build_babylonian_tower_on(*fields)
      babylonian_options = fields.last.is_a?(Hash) ? fields.pop : {}
      babylonian_options[:locale]          ||= lambda { |r, f| I18n.locale }
      babylonian_options[:default_locale]  ||= lambda { |r, f| I18n.default_locale }
      babylonian_options[:fallback]        = true if babylonian_options[:fallback].nil?
      
      fields.each do |field|
        instance_variable_set(:"@babylonian_options_for_#{field}", babylonian_options)
        
        # Alias method chain the field to a translated value
        # @param [Symbol] locale Pass a locale to get the field translation in this specific locale
        # @return [String, NilClass] Either the string with the translation, the fallback, the placeholder or nil
        # @example Call a field in italian
        #   your_instance.field(:it) #=> "Translation" 
        #
        define_method :"#{field}_translated" do |locale=nil|
          field_hash    = send(:"#{field}_hash")
          translation   = field_hash[locale || evaluate_babylonian_option!(:locale, field)]
          translation   = field_hash[evaluate_babylonian_option!(:default_locale, field)] if (translation.nil? or translation.empty?) and evaluate_babylonian_option!(:fallback, field)
          (translation.nil? or translation.empty?) ? evaluate_babylonian_option!(:placeholder, field) : translation
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
        
        # Return all the languages stored
        # @return [Array] An array containing all languages stored in the field
        #
        define_method :"#{field}_languages" do
          send(:"#{field}_hash").keys
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
            current_hash.merge! evaluate_babylonian_option!(:locale, field) => data
          elsif data.is_a?(Hash)
            current_hash.merge! data
          end
          
          send(:"#{field}_raw=", YAML.dump(current_hash.delete_if{|k,v| v.nil? || v.empty? }))
        end
        alias_method :"#{field}_raw=", :"#{field}="
        alias_method :"#{field}=", :"#{field}_translated="
      end
      
      define_method :evaluate_babylonian_option! do |option, field|
        options = self.class.instance_variable_get :"@babylonian_options_for_#{field}"

        o = options[option]
        if o.is_a? Proc
          o.call self, field
        elsif o.is_a? Symbol
          send o
        elsif o.is_a? String
          o.to_sym
        else
          o
        end
      end
    end
  end
end