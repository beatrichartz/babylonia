require 'spec_helper'

describe Babylonia::ClassMethods do
  
  class BabylonianFields
    extend Babylonia::ClassMethods
    
    attr_accessor :marshes, :grasslands, :desert, :sky
    
    build_babylonian_tower_on :marshes
    build_babylonian_tower_on :grasslands, locales: [:pi, :de, :en], locale: :architects_tongue, default_locale: lambda {|r, f| r.builders_tongue || :en }
    build_babylonian_tower_on :desert, :sky, fallback: false, placeholder: lambda {|r, field| "<span class='missing translation'>Translation missing for " + field.to_s + "</span>"}
  
    def architects_tongue
      :pi
    end
    
    def builders_tongue
      nil
    end
  end
  
  context "without options" do
    subject { BabylonianFields.new }
    before(:each) do
      I18n.stub locale: :en, default_locale: :de
    end
    
    describe "#marshes" do
      context "with no data" do
        it "should return nil" do
          subject.marshes.should be_nil
        end
      end
      context "with some raw data" do
        before(:each) do
          subject.stub marshes_raw: "---\n:en: TRANSLATION\n:de: FALLBACK"
        end
        it "should return the data" do
          subject.marshes.should == "TRANSLATION"
        end
        context "with a locale argument" do
          it "should return the translation in that locale" do
            subject.marshes(:de).should == 'FALLBACK'
          end
        end
      end
      context "with only fallback data" do
        before(:each) do
          subject.stub marshes_raw: "---\n:de: FALLBACK"
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
          subject.stub marshes_raw: "---\n:it: NO_FALLBACK"
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
    describe "marshes=" do
      context "with no existing data" do
        context "with a string" do
          it "should set the current locales data" do
            subject.marshes = 'SOME ENGLISH'
            subject.marshes_raw.should == "---\n:en: SOME ENGLISH\n"
            subject.marshes.should == 'SOME ENGLISH'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.marshes = {en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
            subject.marshes_raw.should == "---\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
            subject.marshes.should == 'SOME ENGLISH'
            subject.marshes(:de).should == 'SOME DEUTSCH'
          end
        end
      end
      context "with existing data" do
        before(:each) do
          subject.marshes_raw = "---\n:it: SOME ITALIAN"
        end
        context "with a string" do
          it "should set the current locales data" do
            subject.marshes = 'SOME ENGLISH'
            subject.marshes_raw.should == "---\n:it: SOME ITALIAN\n:en: SOME ENGLISH\n"
            subject.marshes.should == 'SOME ENGLISH'
            subject.marshes(:it).should == 'SOME ITALIAN'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.marshes = {en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
            subject.marshes_raw.should == "---\n:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
            subject.marshes.should == 'SOME ENGLISH'
            subject.marshes(:de).should == 'SOME DEUTSCH'
            subject.marshes(:it).should == 'SOME ITALIAN'
          end
        end
      end
    end
    describe "marshes_hash" do
      before(:each) do
        subject.marshes_raw = "---\n:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the loaded hash of the field" do
        subject.marshes_hash.should == {it: 'SOME ITALIAN', en: 'SOME ENGLISH', de: 'SOME DEUTSCH'}
      end
    end
    describe "marshes_languages" do
      before(:each) do
        subject.marshes_raw = "---\n:it: SOME ITALIAN\n:en: SOME ENGLISH\n:de: SOME DEUTSCH\n"
      end
      it "should return the translated languages of the field" do
        subject.marshes_languages.sort.should == [:de, :en, :it]
      end
    end
  end
  
  context "with options" do
    subject { BabylonianFields.new }
    before(:each) do
      I18n.stub locale: :en, default_locale: :de
    end
    
    describe "#grasslands" do
      context "with no data" do
        it "should return nil" do
          subject.grasslands.should be_nil
        end
      end
      context "with some raw data" do
        before(:each) do
          subject.stub grasslands_raw: "---\n:pi: TRANSLATION\n:de: FALLBACK"
        end
        it "should return the data" do
          subject.grasslands.should == "TRANSLATION"
        end
        context "with a locale argument" do
          it "should return the translation in that locale" do
            subject.grasslands(:de).should == 'FALLBACK'
          end
        end
      end
      context "with only fallback data" do
        before(:each) do
          subject.stub grasslands_raw: "---\n:en: FALLBACK"
        end
        it "should return the fallback data" do
          subject.grasslands.should == "FALLBACK"
        end
        context "with a locale argument" do
          it "should return the fallback" do
            subject.grasslands(:pi).should == 'FALLBACK'
          end
        end
      end
      context "with data in neither the current nor the fallback language" do
        before(:each) do
          subject.stub grasslands_raw: "---\n:it: NO_FALLBACK"
        end
        it "should return the fallback data" do
          subject.grasslands.should be_nil
        end
        context "with a locale argument" do
          it "should return the fallback" do
            subject.grasslands(:en).should be_nil
          end
        end
      end
      context "with fallback data, but fallback disabled" do
        before(:each) do
          subject.stub desert_raw: "---\n:it: NO_FALLBACK"
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
            subject.grasslands_raw.should == "---\n:pi: SOME PIRATE\n"
            subject.grasslands.should == 'SOME PIRATE'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.grasslands = {pi: 'SOME PIRATE', de: 'SOME DEUTSCH'}
            subject.grasslands_raw.should == "---\n:pi: SOME PIRATE\n:de: SOME DEUTSCH\n"
            subject.grasslands.should == 'SOME PIRATE'
            subject.grasslands(:de).should == 'SOME DEUTSCH'
          end
        end
      end
      context "with existing data" do
        before(:each) do
          subject.grasslands_raw = "---\n:it: SOME ITALIAN"
        end
        context "with a string" do
          it "should set the current locales data" do
            subject.grasslands = 'SOME PIRATE'
            subject.grasslands_raw.should == "---\n:it: SOME ITALIAN\n:pi: SOME PIRATE\n"
            subject.grasslands.should == 'SOME PIRATE'
            subject.grasslands(:it).should == 'SOME ITALIAN'
          end
        end
        context "with a hash" do
          it "should merge that hash with the existing data, if any" do
            subject.grasslands = {pi: 'SOME PIRATE', de: 'SOME DEUTSCH'}
            subject.grasslands_raw.should == "---\n:it: SOME ITALIAN\n:pi: SOME PIRATE\n:de: SOME DEUTSCH\n"
            subject.grasslands.should == 'SOME PIRATE'
            subject.grasslands(:de).should == 'SOME DEUTSCH'
            subject.grasslands(:it).should == 'SOME ITALIAN'
          end
        end
        context "deleting a value" do
          context "with a string" do
            it "should be deleted" do
              subject.grasslands = ''
              subject.grasslands.should be_nil
            end
          end
          context "with nil" do
            it "should be deleted" do
              subject.grasslands = nil
              subject.grasslands.should be_nil
            end 
          end
          context "with a hash containing an empty string" do
            it "should be deleted" do
              subject.grasslands = {it: ''}
              subject.grasslands(:it).should be_nil
            end 
          end
          context "with a hash containing nil" do
            it "should be deleted" do
              subject.grasslands = {it: nil}
              subject.grasslands(:it).should be_nil
            end 
          end
        end
      end
    end
  end
  
  
end