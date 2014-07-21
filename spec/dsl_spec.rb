require 'spec_helper'

module Beetle
  describe DSL do

    subject { DSL.new(:foo_table) }

    describe '#stage_table' do
      before do
        allow(Beetle.config).to receive(:stage_schema) { 'stage' }
      end

      it 'returns the stage table name including the schema' do
        expect(subject.stage_table).to eql('"stage"."foo_table"')
      end
    end

    describe '#external_source' do
      it 'returns the external source‘s identifier' do
        expect(subject.external_source).to eql('source')
      end
    end

    describe '#combined_key' do
      it 'returns an SQL string for combined external ids' do
        expect(subject.combined_key('foo', 'bar')).to eql(
          %q('[' || foo || ',' || bar || ']')
        )
      end

      it 'works with multiple arguments' do
        expect(subject.combined_key('foo', 'bar', 'baz')).to eql(
          %q('[' || foo || ',' || bar || ',' || baz || ']')
        )
      end
    end

    describe '#import_run_id' do
      let(:id) { double(:id) }

      before do
        allow(Beetle.config).to receive(:import_run_id) { id }
      end

      it 'returns the import run id defined in the config' do
        expect(subject.import_run_id).to eql(id)
      end
    end

  end
end
