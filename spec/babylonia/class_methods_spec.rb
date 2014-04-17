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
          expect(subject.marshes).to be_nil
        end
      end
      context "with some raw data" do
        before(:each) do
          subject.stub marshes_raw: "#{yml_file}:en: TRANSLATION\n:de: FALLBACK"
        end
        it "should return the data" do
          expect(subject.marshes).to eq("TRANSLATION")
        end
        context "with a locale argument" do
          it "should return the translation in that locale" do
            expect(subject.marshes(:de)).to eq('FALLBACK')
          end
          context "with fallback to false" do
            it "should return nil" do
              expect(subject.marshes(:it, fallback: false)).to be_nil
            end
          end
        end
      end
      context "with only fallback data" do
        before(:each) do
          subject.stub marshes_raw: "#{yml_file}:de: FALLBACK"
        end
        it "should return the fallback data" do
          expect(subject.marshes).to eq("FALLBACK")
        end
        context "with a locale argument" do
          it "should return the fallback" do
            expect(subject.marshes(:en)).to eq('FALLBACK')
          end
        end
      end
      context "with data in neither the current nor the fallback language" do
        before(:each) do
          subject.stub marshes_raw: "#{yml_file}:it: NO_FALLBACK"
        end
        it "should return the fallback data" do
          expect(subject.marshes).to be_nil
        end
        context "with a locale argument" do
          it "should return the fallback" do
            expect(subject.marshes(:en)).to be_nil
          end
        end
      end
    end
    describe "methods via method missing" do
      context "getters" do
        context "with the missing method matching the pattern FIELD_LANGUAGE" do
          let(:meth) { :marshes_en }
          it "should call the attribute method with an argument" do
            expect(subject).to receive(:marshes).with(:en, {}).once
            subject.send(meth)
          end
        end
        context "with the missing method matching the pattern FIELD_LANGUAGE and a fallback argument" do
          let(:meth) { :marshes_en }
          it "should call the attribute method with the fallback argument" do
            expect(subject).to receive(:marshes).with(:en, {fallback: true}).once
            subject.send(meth, fallback: true)
          end
        end
        context "with the missing method not matching the pattern" do
          let(:meth) { :marshes_something_else_entirely }
          it "should raise Method Missing" do
            expect { subject.send(meth) }.to raise_error(NoMethodError)
          end
        end
        context "with the missing method having underscores in the original method name" do
          let(:meth) { :some_attr_en }
          it "should call the attribute method with an argument" do
            expect(subject).to receive(:some_attr).with(:en, {}).once
            subject.send(meth)
          end
        end
        context "with the missing method matching the pattern but an unavailable language" do
          let(:meth) { :marshes_he }
          it "should raise Method Missing" do
            expect { subject.send(meth) }.to raise_error(NoMethodError)
          end
        end
      end
      context "setters" do
        context "with the missing method matching the pattern FIELD_LANGUAGE=" do
          let(:meth) { :marshes_en= }
          it "should call the attribute method with an argument" do
            expect(subject).to receive(:marshes=).with(en: 'DATA').once
            subject.send(meth, 'DATA')
          end
        end
        context "with the missing method not matching the pattern" do
          let(:meth) { :marshes_something_else_entirely }
          it "should raise Method Missing" do
            expect { subject.send(meth) }.to raise_error(NoMethodError)
          end
        end
        context "with the missing method matching the pattern but an unavailable language" do
          let(:meth) { :marshes_he }
          it "should raise Method Missing" do
            expect { subject.send(meth) }.to raise_error(NoMethodError)
          end
        end
      end
    end
    describe "#marshes=" do
      context "with no existing data" do
        context "with a string" do
          it "should set the current locales data" do
            subject.marshes = 'SOME ENGLISH'
            expect(subject.marshes_raw).to eq("#{yml_file}:en: SOME ENGLISH\n")
            expect(subject.marshes).to eq('SOME ENGLISH')
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.marshes = {en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
            expect(subject.marshes_raw).to eq("#{yml_file}:en: SOME ENGLISH\n:de: SOME DEUTSCH\n")
            expect(subject.marshes).to eq('SOME ENGLISH')
            expect(subject.marshes(:de)).to eq('SOME DEUTSCH')
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
            expect(subject.marshes_raw).to eq("#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n")
            expect(subject.marshes).to eq('SOME ENGLISH')
            expect(subject.marshes(:it)).to eq('SOME ITALIAN')
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.marshes = {en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
            expect(subject.marshes_raw).to eq("#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n")
            expect(subject.marshes).to eq('SOME ENGLISH')
            expect(subject.marshes(:de)).to eq('SOME DEUTSCH')
            expect(subject.marshes(:it)).to eq('SOME ITALIAN')
          end
        end
      end
    end
    describe "#marshes_hash" do
      before(:each) do
        subject.marshes_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the loaded hash of the field" do
        expect(subject.marshes_hash).to eq({it: 'SOME ITALIAN', en: 'SOME ENGLISH', de: 'SOME DEUTSCH'})
      end
    end
    describe "#locales" do
      before(:each) do
        subject.marshes_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.sky_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.some_attr_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the translated languages of the field" do
        expect(subject.locales.sort).to eq([:de, :en, :it])
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
          expect(subject).to be_has_locale(:it)
        end
      end
      context "with the locale not present in the translation hashes" do
        it "should return true" do
          expect(subject).not_to be_has_locale(:pi)
        end
      end
    end
    describe "#available_locales" do
      before(:each) do
        I18n.stub available_locales: [:de, :en]
      end
      it "should return available locales" do
        expect(subject.available_locales.sort).to eq([:de, :en])
      end
    end
    describe "#has_available_locale" do
      before(:each) do
        I18n.stub available_locales: [:de, :en]
      end
      context "with an available locale" do
        it "should return true" do
          expect(subject).to be_has_available_locale(:de)
        end
      end
      context "with an available locale" do
        it "should return true" do
          expect(subject).not_to be_has_available_locale(:it)
        end
      end
    end
    describe "#localized?" do
      context "with a localized attribute" do
        it "should return true" do
          expect(subject).to be_localized(:sky)
        end
      end
      context "with a unlocalized attribute" do
        it "should return true" do
          expect(subject).not_to be_localized(:desert)
        end
      end
    end
    describe "#missing_translation_placeholder" do
      it "should return nil" do
        expect(subject.missing_translation_placeholder('FIELD')).to be_nil
      end
    end
    describe "#locale_fallback?" do
      it "should return false" do
        expect(subject).to be_locale_fallback
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
          expect(subject.grasslands).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
        end
      end
      context "with some raw data" do
        before(:each) do
          subject.stub grasslands_raw: "#{yml_file}:pi: TRANSLATION\n:de: FALLBACK"
        end
        it "should return the data" do
          expect(subject.grasslands).to eq("TRANSLATION")
        end
        context "with a locale argument" do
          it "should return the translation in that locale" do
            expect(subject.grasslands(:de)).to eq('FALLBACK')
          end
          context "with fallback to false" do
            it "should return the placeholder" do
              expect(subject.grasslands(:gb, fallback: false)).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
            end
          end
        end
      end
      context "with only fallback data" do
        before(:each) do
          subject.stub grasslands_raw: "#{yml_file}:en: FALLBACK"
        end
        it "should not return the fallback data" do
          expect(subject.grasslands).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
        end
        context "with a locale argument" do
          it "should return the not return the fallback" do
            expect(subject.grasslands(:pi)).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
          end
        end
      end
      context "with data in neither the current nor the fallback language" do
        before(:each) do
          subject.stub grasslands_raw: "#{yml_file}:it: NO_FALLBACK"
        end
        it "should return the fallback data" do
          expect(subject.grasslands).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
        end
        context "with a locale argument" do
          it "should return the fallback" do
            expect(subject.grasslands(:en)).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
          end
        end
      end
      context "with fallback data, but fallback disabled" do
        before(:each) do
          subject.stub desert_raw: "#{yml_file}:it: NO_FALLBACK"
        end
        it "should not return the fallback data and display the placeholder" do
          expect(subject.desert).to eq("<span class='missing translation'>Translation missing for desert</span>")
        end
        context "with a locale argument" do
          it "should not return the fallback and display the placeholder" do
            expect(subject.desert(:pi)).to eq("<span class='missing translation'>Translation missing for desert</span>")
          end
        end
      end
    end
    describe "grasslands=" do
      context "with no existing data" do
        context "with a string" do
          it "should set the current locales data" do
            subject.grasslands = 'SOME PIRATE'
            expect(subject.grasslands_raw).to eq("#{yml_file}:pi: SOME PIRATE\n")
            expect(subject.grasslands).to eq('SOME PIRATE')
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.grasslands = {pi: 'SOME PIRATE', de: 'SOME DEUTSCH'}
            expect(subject.grasslands_raw).to eq("#{yml_file}:pi: SOME PIRATE\n:de: SOME DEUTSCH\n")
            expect(subject.grasslands).to eq('SOME PIRATE')
            expect(subject.grasslands(:de)).to eq('SOME DEUTSCH')
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
            expect(subject.grasslands_raw).to eq("#{yml_file}:it: SOME ITALIAN\n:pi: SOME PIRATE\n")
            expect(subject.grasslands).to eq('SOME PIRATE')
            expect(subject.grasslands(:it)).to eq('SOME ITALIAN')
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.grasslands = {pi: 'SOME PIRATE', de: 'SOME DEUTSCH'}
            expect(subject.grasslands_raw).to eq("#{yml_file}:it: SOME ITALIAN\n:pi: SOME PIRATE\n:de: SOME DEUTSCH\n")
            expect(subject.grasslands).to eq('SOME PIRATE')
            expect(subject.grasslands(:de)).to eq('SOME DEUTSCH')
            expect(subject.grasslands(:it)).to eq('SOME ITALIAN')
          end
        end
        context "deleting a value" do
          context "with a string" do
            it "should be deleted" do
              subject.grasslands = ''
              expect(subject.grasslands).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
            end
          end
          context "with nil" do
            it "should be deleted" do
              subject.grasslands = nil
              expect(subject.grasslands).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
            end 
          end
          context "with a hash containing an empty string" do
            it "should be deleted" do
              subject.grasslands = {it: ''}
              expect(subject.grasslands(:it)).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
            end 
          end
          context "with a hash containing nil" do
            it "should be deleted" do
              subject.grasslands = {it: nil}
              expect(subject.grasslands(:it)).to eq("<span class='missing translation'>Translation missing for grasslands</span>")
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
        expect(subject.locales.sort).to eq([:de, :en, :it])
      end
    end
    describe "#has_locale?" do
      before(:each) do
        subject.grasslands_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
        subject.desert_raw = "#{yml_file}:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      context "with the locale present in the translation hashes" do
        it "should return true" do
          expect(subject).to be_has_locale(:it)
        end
      end
      context "with the locale not present in the translation hashes" do
        it "should return true" do
          expect(subject).not_to be_has_locale(:pi)
        end
      end
    end
    describe "#available_locales" do
      it "should return available locales" do
        expect(subject.available_locales.sort).to eq([:de, :en, :it, :pi])
      end
    end
    describe "#has_available_locale" do
      context "with an available locale" do
        it "should return true" do
          expect(subject).to be_has_available_locale(:pi)
        end
      end
      context "with an available locale" do
        it "should return true" do
          expect(subject).not_to be_has_available_locale(:gb)
        end
      end
    end
    describe "#localized?" do
      context "with a localized attribute" do
        it "should return true" do
          expect(subject).to be_localized(:grasslands)
        end
      end
      context "with a unlocalized attribute" do
        it "should return true" do
          expect(subject).not_to be_localized(:fields)
        end
      end
    end
    describe "#missing_translation_placeholder" do
      it "should return the defined placeholder for the field" do
        expect(subject.missing_translation_placeholder('FIELD')).to eq("<span class='missing translation'>Translation missing for FIELD</span>")
      end
    end
    describe "#locale_fallback?" do
      it "should return false" do
        expect(subject).not_to be_locale_fallback
      end
    end
  end
end