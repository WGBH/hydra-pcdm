require 'spec_helper'

describe Hydra::PCDM::Object do

  let(:object1) { Hydra::PCDM::Object.create }
  let(:object2) { Hydra::PCDM::Object.create }
  let(:object3) { Hydra::PCDM::Object.create }

  describe '#objects=' do
    it 'should aggregate objects' do
      object1.objects = [object2, object3]
      object1.save
      expect(object1.objects).to eq [object2, object3]
    end
  end

  describe 'Related objects' do
    before do
      object1.related_objects = [object2]
      object1.save
    end

    it 'persists' do
      expect(object1.reload.related_objects).to eq [object2]
    end
  end

  describe '#files' do
    let(:object) { described_class.create }
    let(:file1) { object.files.build }
    let(:file2) { object.files.build }

    before do
      file1.content = "I'm a file"
      file2.content = "I am too"
      object.save!
    end

    subject { described_class.find(object.id).files }

    it { is_expected.to eq [file1, file2] }
  end

  describe "filtering files" do
    let(:object) { described_class.create }
    let(:thumbnail)   do
      file = object.files.build
      Hydra::PCDM::AddTypeToFile.call(file, pcdm_thumbnail_uri)
    end

    let(:file)                { object.files.build }
    let(:pcdm_thumbnail_uri)  { ::RDF::URI("http://pcdm.org/ThumbnailImage") }

    before do
      object.files = [file]
      object.save
    end

    describe "filter_files_by_type" do
      context "when the object has files with that type" do
        before do
          thumbnail
        end
        it "allows you to filter the contained files by type URI" do
          expect( object.filter_files_by_type(pcdm_thumbnail_uri) ).to eq [thumbnail]
        end
        it "only overrides the #files method when you specify :type" do
          expect( object.files ).to eq [file, thumbnail]
        end
      end
      context "when the object does NOT have any files with that type" do
        it "returns an empty array" do
          expect( object.filter_files_by_type(pcdm_thumbnail_uri) ).to eq []
        end
      end
    end

    describe "file_of_type" do
      context "when the object has files with that type" do
        before do
          thumbnail
        end
        it "returns the first file with the requested type" do
          expect( object.file_of_type(pcdm_thumbnail_uri) ).to eq thumbnail
        end
      end
      context "when the object does NOT have any files with that type" do
        it "initializes a contained file with the requested type" do
          returned_file =  object.file_of_type(pcdm_thumbnail_uri)
          expect(object.files).to include(returned_file)
          expect(returned_file).to be_new_record
          expect(returned_file.metadata_node.get_values(:type)).to include(pcdm_thumbnail_uri)
        end
      end
    end
  end



  describe ".indexer" do
    after do
      Object.send(:remove_const, :Foo)
    end

    context "without overriding" do
      before do
        class Foo < ActiveFedora::Base
          include Hydra::PCDM::ObjectBehavior
        end
      end

      subject { Foo.indexer }
      it { is_expected.to eq Hydra::PCDM::ObjectIndexer }
    end

    context "when overridden with AS::Concern" do
      before do
        module IndexingStuff
          extend ActiveSupport::Concern

          class AltIndexer; end

          module ClassMethods
            def indexer
              AltIndexer
            end
          end
        end

        class Foo < ActiveFedora::Base
          include Hydra::PCDM::ObjectBehavior
          include IndexingStuff
        end
      end

      subject { Foo.indexer }
      it { is_expected.to eq IndexingStuff::AltIndexer }
    end
  end

end
