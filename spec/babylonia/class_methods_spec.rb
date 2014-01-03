require 'spec_helper'

describe Babylonia::ClassMethods do  
  let(:yml_file) { RUBY_ENGINE == 'rbx' ? "--- \n" : "---\n" }
  
  context "without options" do
    subject { BabylonianFields.new }
    class BabylonianFields
      extend Babylonia::ClassMethods
    
      attr_accessor :marshes, :sky, :some_attr
    
      build_babylonian_tower_on :marshes, :sky, :some_attr
    end
    
    before(:each) do
      I18n.stub locale: :en, default_locale: :de, available_locales: [:de, :en, :it]
    end
    
    describe "#marshes" do
      context "with no data" do
        it "should return nil" do
          subject.marshes.should be_nil
        end
      end
      context "with some raw data" do
        before(:each) do
          subject.stub marshes_raw: "#{yml_file}:en: TRANSLATION\n:de: FALLBACK"
        end
        it "should return the data" do
          subject.marshes.should == "TRANSLATION"
        end
        context "with a locale argument" do
          it "should return the translation in that locale" do
            subject.marshes(:de).should == 'FALLBACK'
          end
          context "with fallback to false" do
            it "should return nil" do
              subject.marshes(:it, fallback: false).should be_nil
            end
          end
        end
      end
      context "with only fallback data" do
        before(:each) do
          subject.stub marshes_raw: "#{yml_file}:de: FALLBACK"
        end
        it "should return the fallback data" do
          subject.marshes.should == "FALLBACK"
        end
        context "with a locale argument" do
          it "should return the fallback" do
            subject.marshes(:en).should == 'FALLBACK'
          end
        end
      end
      context "with data in neither the current nor the fallback language" do
        before(:each) do
          subject.stub marshes_raw: "#{yml_file}:it: NO_FALLBACK"
        end
        it "should return the fallback data" do
          subject.marshes.should be_nil
        end
        context "with a locale argument" do
          it "should return the fallback" do
            subject.marshes(:en).should be_nil
          end
        end
      end
    end
    describe "methods via method missing" do
      context "getters" do
        context "with the missing method matching the pattern FIELD_LANGUAGE" do
          let(:meth) { :marshes_en }
          it "should call the attribute method with an argument" do
            subject.should_receive(:marshes).with(:en, {}).once
            subject.send(meth)
          end
        end
        context "with the missing method matching the pattern FIELD_LANGUAGE and a fallback argument" do
          let(:meth) { :marshes_en }
          it "should call the attribute method with the fallback argument" do
            subject.should_receive(:marshes).with(:en, {fallback: true}).once
            subject.send(meth, fallback: true)
          end
        end
        context "with the missing method not matching the pattern" do
          let(:meth) { :marshes_something_else_entirely }
          it "should raise Method Missing" do
            lambda { subject.send(meth) }.should raise_error(NoMethodError)
          end
        end
        context "with the missing method having underscores in the original method name" do
          let(:meth) { :some_attr_en }
          it "should call the attribute method with an argument" do
            subject.should_receive(:some_attr).with(:en, {}).once
            subject.send(meth)
          end
        end
        context "with the missing method matching the pattern but an unavailable language" do
          let(:meth) { :marshes_he }
          it "should raise Method Missing" do
            lambda { subject.send(meth) }.should raise_error(NoMethodError)
          end
        end
      end
      context "setters" do
        context "with the missing method matching the pattern FIELD_LANGUAGE=" do
          let(:meth) { :marshes_en= }
          it "should call the attribute method with an argument" do
            subject.should_receive(:marshes=).with(en: 'DATA').once
            subject.send(meth, 'DATA')
          end
        end
        context "with the missing method not matching the pattern" do
          let(:meth) { :marshes_something_else_entirely }
          it "should raise Method Missing" do
            lambda { subject.send(meth) }.should raise_error(NoMethodError)
          end
        end
        context "with the missing method matching the pattern but an unavailable language" do
          let(:meth) { :marshes_he }
          it "should raise Method Missing" do
            lambda { subject.send(meth) }.should raise_error(NoMethodError)
          end
        end
      end
    end
    describe "#marshes=" do
      context "with no existing data" do
        context "with a string" do
          it "should set the current locales data" do
            subject.marshes = 'SOME ENGLISH'
            subject.marshes_raw.should == "#{yml_file}:en: SOME ENGLISH\n"
            subject.marshes.should == 'SOME ENGLISH'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.marshes = {en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
            subject.marshes_raw.should == "#{yml_file}:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
            subject.marshes.should == 'SOME ENGLISH'
            subject.marshes(:de).should == 'SOME DEUTSCH'
          end
        end
      end
      context "with existing data" do
        before(:each) do
          subject.marshes_raw = "#{yml_file}:it: SOME ITALIAN"
        end
        context "with a string" do
          it "should set the current locales data" do
            subject.marshes = 'SOME ENGLISH'
            subject.marshes_raw.should == "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n"
            subject.marshes.should == 'SOME ENGLISH'
            subject.marshes(:it).should == 'SOME ITALIAN'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.marshes = {en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
            subject.marshes_raw.should == "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
            subject.marshes.should == 'SOME ENGLISH'
            subject.marshes(:de).should == 'SOME DEUTSCH'
            subject.marshes(:it).should == 'SOME ITALIAN'
          end
        end
      end
    end
    describe "#marshes_hash" do
      before(:each) do
        subject.marshes_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the loaded hash of the field" do
        subject.marshes_hash.should == {it: 'SOME ITALIAN', en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
      end
    end
    describe "#locales" do
      before(:each) do
        subject.marshes_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.sky_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.some_attr_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the translated languages of the field" do
        subject.locales.sort.should == [:de, :en, :it]
      end
    end
    describe "#has_locale?" do
      before(:each) do
        subject.marshes_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.sky_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.some_attr_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      context "with the locale present in the translation hashes" do
        it "should return true" do
          subject.should be_has_locale(:it)
        end
      end
      context "with the locale not present in the translation hashes" do
        it "should return true" do
          subject.should_not be_has_locale(:pi)
        end
      end
    end
    describe "#available_locales" do
      before(:each) do
        I18n.stub available_locales: [:de, :en]
      end
      it "should return available locales" do
        subject.available_locales.sort.should == [:de, :en]
      end
    end
    describe "#has_available_locale" do
      before(:each) do
        I18n.stub available_locales: [:de, :en]
      end
      context "with an available locale" do
        it "should return true" do
          subject.should be_has_available_locale(:de)
        end
      end
      context "with an available locale" do
        it "should return true" do
          subject.should_not be_has_available_locale(:it)
        end
      end
    end
    describe "#localized?" do
      context "with a localized attribute" do
        it "should return true" do
          subject.should be_localized(:sky)
        end
      end
      context "with a unlocalized attribute" do
        it "should return true" do
          subject.should_not be_localized(:desert)
        end
      end
    end
    describe "#missing_translation_placeholder" do
      it "should return nil" do
        subject.missing_translation_placeholder('FIELD').should be_nil
      end
    end
    describe "#locale_fallback?" do
      it "should return false" do
        subject.should be_locale_fallback
      end
    end
  end
  
  context "with options opposite the defaults" do
    class BabylonianFieldsWithOptions
      extend Babylonia::ClassMethods
    
      attr_accessor :grasslands, :desert
    
      build_babylonian_tower_on :grasslands, :desert,
                                available_locales: [:pi, :de, :en, :it],
                                locale: :architects_tongue,
                                default_locale: lambda {|r| r.builders_tongue || :en },
                                fallback: false,
                                placeholder: lambda {|r, field| "<span class='missing translation'>Translation missing for " + field.to_s + "</span>"}
  
      def architects_tongue
        :pi
      end
    
      def builders_tongue
        nil
      end
    end
    
    subject { BabylonianFieldsWithOptions.new }
    before(:each) do
      I18n.stub locale: :en, default_locale: :de
    end
    
    describe "#grasslands" do
      context "with no data" do
        it "should return the placeholder" do
          subject.grasslands.should == "<span class='missing translation'>Translation missing for grasslands</span>"
        end
      end
      context "with some raw data" do
        before(:each) do
          subject.stub grasslands_raw: "#{yml_file}:pi: TRANSLATION\n:de: FALLBACK"
        end
        it "should return the data" do
          subject.grasslands.should == "TRANSLATION"
        end
        context "with a locale argument" do
          it "should return the translation in that locale" do
            subject.grasslands(:de).should == 'FALLBACK'
          end
          context "with fallback to false" do
            it "should return the placeholder" do
              subject.grasslands(:gb, fallback: false).should == "<span class='missing translation'>Translation missing for grasslands</span>"
            end
          end
        end
      end
      context "with only fallback data" do
        before(:each) do
          subject.stub grasslands_raw: "#{yml_file}:en: FALLBACK"
        end
        it "should not return the fallback data" do
          subject.grasslands.should == "<span class='missing translation'>Translation missing for grasslands</span>"
        end
        context "with a locale argument" do
          it "should return the not return the fallback" do
            subject.grasslands(:pi).should == "<span class='missing translation'>Translation missing for grasslands</span>"
          end
        end
      end
      context "with data in neither the current nor the fallback language" do
        before(:each) do
          subject.stub grasslands_raw: "#{yml_file}:it: NO_FALLBACK"
        end
        it "should return the fallback data" do
          subject.grasslands.should == "<span class='missing translation'>Translation missing for grasslands</span>"
        end
        context "with a locale argument" do
          it "should return the fallback" do
            subject.grasslands(:en).should == "<span class='missing translation'>Translation missing for grasslands</span>"
          end
        end
      end
      context "with fallback data, but fallback disabled" do
        before(:each) do
          subject.stub desert_raw: "#{yml_file}:it: NO_FALLBACK"
        end
        it "should not return the fallback data and display the placeholder" do
          subject.desert.should == "<span class='missing translation'>Translation missing for desert</span>"
        end
        context "with a locale argument" do
          it "should not return the fallback and display the placeholder" do
            subject.desert(:pi).should == "<span class='missing translation'>Translation missing for desert</span>"
          end
        end
      end
    end
    describe "grasslands=" do
      context "with no existing data" do
        context "with a string" do
          it "should set the current locales data" do
            subject.grasslands = 'SOME PIRATE'
            subject.grasslands_raw.should == "#{yml_file}:pi: SOME PIRATE\n"
            subject.grasslands.should == 'SOME PIRATE'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.grasslands = {pi: 'SOME PIRATE', de: 'SOME DEUTSCH'}
            subject.grasslands_raw.should == "#{yml_file}:pi: SOME PIRATE\n:de: SOME DEUTSCH\n"
            subject.grasslands.should == 'SOME PIRATE'
            subject.grasslands(:de).should == 'SOME DEUTSCH'
          end
        end
      end
      context "with existing data" do
        before(:each) do
          subject.grasslands_raw = "#{yml_file}:it: SOME ITALIAN"
        end
        context "with a string" do
          it "should set the current locales data" do
            subject.grasslands = 'SOME PIRATE'
            subject.grasslands_raw.should == "#{yml_file}:it: SOME ITALIAN\n:pi: SOME PIRATE\n"
            subject.grasslands.should == 'SOME PIRATE'
            subject.grasslands(:it).should == 'SOME ITALIAN'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.grasslands = {pi: 'SOME PIRATE', de: 'SOME DEUTSCH'}
            subject.grasslands_raw.should == "#{yml_file}:it: SOME ITALIAN\n:pi: SOME PIRATE\n:de: SOME DEUTSCH\n"
            subject.grasslands.should == 'SOME PIRATE'
            subject.grasslands(:de).should == 'SOME DEUTSCH'
            subject.grasslands(:it).should == 'SOME ITALIAN'
          end
        end
        context "deleting a value" do
          context "with a string" do
            it "should be deleted" do
              subject.grasslands = ''
              subject.grasslands.should == "<span class='missing translation'>Translation missing for grasslands</span>"
            end
          end
          context "with nil" do
            it "should be deleted" do
              subject.grasslands = nil
              subject.grasslands.should == "<span class='missing translation'>Translation missing for grasslands</span>"
            end 
          end
          context "with a hash containing an empty string" do
            it "should be deleted" do
              subject.grasslands = {it: ''}
              subject.grasslands(:it).should == "<span class='missing translation'>Translation missing for grasslands</span>"
            end 
          end
          context "with a hash containing nil" do
            it "should be deleted" do
              subject.grasslands = {it: nil}
              subject.grasslands(:it).should == "<span class='missing translation'>Translation missing for grasslands</span>"
            end 
          end
        end
      end
    end
    describe "#locales" do
      before(:each) do
        subject.grasslands_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.desert_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the translated languages of the field" do
        subject.locales.sort.should == [:de, :en, :it]
      end
    end
    describe "#has_locale?" do
      before(:each) do
        subject.grasslands_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.desert_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      context "with the locale present in the translation hashes" do
        it "should return true" do
          subject.should be_has_locale(:it)
        end
      end
      context "with the locale not present in the translation hashes" do
        it "should return true" do
          subject.should_not be_has_locale(:pi)
        end
      end
    end
    describe "#available_locales" do
      it "should return available locales" do
        subject.available_locales.sort.should == [:de, :en, :it, :pi]
      end
    end
    describe "#has_available_locale" do
      context "with an available locale" do
        it "should return true" do
          subject.should be_has_available_locale(:pi)
        end
      end
      context "with an available locale" do
        it "should return true" do
          subject.should_not be_has_available_locale(:gb)
        end
      end
    end
    describe "#localized?" do
      context "with a localized attribute" do
        it "should return true" do
          subject.should be_localized(:grasslands)
        end
      end
      context "with a unlocalized attribute" do
        it "should return true" do
          subject.should_not be_localized(:fields)
        end
      end
    end
    describe "#missing_translation_placeholder" do
      it "should return the defined placeholder for the field" do
        subject.missing_translation_placeholder('FIELD').should == "<span class='missing translation'>Translation missing for FIELD</span>"
      end
    end
    describe "#locale_fallback?" do
      it "should return false" do
        subject.should_not be_locale_fallback
      end
    end
  end
end