require 'yaml'
require 'i18n'

module Babylonia
  module ClassMethods
    def build_babylonian_tower_on(*fields)
      babylonian_options = fields.last.is_a?(Hash) ? fields.pop : {}
      babylonian_options[:locale]          ||= lambda { |r, f| I18n.locale }
      babylonian_options[:default_locale]  ||= lambda { |r, f| I18n.default_locale }
      babylonian_options[:fallback]        = true if babylonian_options[:fallback].nil?
      
      # loop through fields to define methods such as "name" and "description"
      fields.each do |field|
        instance_variable_set(:"@babylonian_options_for_#{field}", babylonian_options)
        
        define_method :"#{field}_translated" do |locale=nil|
          field_hash    = send(:"#{field}_hash")
          translation   = field_hash[locale || evaluate_babylonian_option!(:locale, field)]
          translation   = field_hash[evaluate_babylonian_option!(:default_locale, field)] if (translation.nil? or translation.empty?) and evaluate_babylonian_option!(:fallback, field)
          (translation.nil? or translation.empty?) ? evaluate_babylonian_option!(:placeholder, field) : translation
        end
        alias_method :"#{field}_raw", field
        alias_method field, :"#{field}_translated"
        
        define_method :"#{field}_hash" do
          field_content = send(:"#{field}_raw")
          field_content.is_a?(String) ? YAML.load(field_content) : {}
        end
        
        define_method :"#{field}_languages" do
          send(:"#{field}_hash").keys
        end
        
        define_method :"#{field}_translated=" do |data|
          current_hash = send(:"#{field}_hash")
          
          if data.is_a?(String)
            current_hash.merge! evaluate_babylonian_option!(:locale, field) => data
          elsif data.is_a?(Hash)
            current_hash.merge! data
          end
          
          send(:"#{field}_raw=", YAML.dump(current_hash))
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
        else
          o
        end
      end
    end
  end
end