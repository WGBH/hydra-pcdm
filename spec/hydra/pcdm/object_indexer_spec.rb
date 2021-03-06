require 'spec_helper'

describe Hydra::PCDM::ObjectIndexer do
  let(:object)        { Hydra::PCDM::Object.new }
  let(:child_object1) { Hydra::PCDM::Object.new(id: '123') }
  let(:child_object2) { Hydra::PCDM::Object.new(id: '456') }
  let(:collection1)   { Hydra::PCDM::Collection.new(id: 'abc') }
  let(:collection2)   { Hydra::PCDM::Collection.new(id: 'def') }
  let(:indexer)       { described_class.new(object) }

  before do
    allow(object).to receive(:ordered_object_ids).and_return([child_object1.id, child_object2.id])
    allow(object).to receive(:member_of_collection_ids).and_return([collection1.id, collection2.id])
  end

  describe '#generate_solr_document' do
    subject { indexer.generate_solr_document }

    it 'has fields' do
      expect(subject[Hydra::PCDM::Config.indexing_object_ids_key]).to eq %w(123 456)
      expect(subject[Hydra::PCDM::Config.indexing_member_of_collection_ids_key]).to eq %w(abc def)
    end
  end
end
