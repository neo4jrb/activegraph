require 'spec_helper'

describe Neo4j::ActiveNode::HasN::DeclRel do
  let(:person_class) {UniqueClass.create } #('Person')}
  let(:company_class) {UniqueClass.create } #('Company')}
  let(:folder_class) {UniqueClass.create } #('FolderNode')}
  let(:files_class) {UniqueClass.create } #('FileNode')}

  describe 'initialize' do

    it 'sets default direction :outgoing' do
      dr = Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class)
      dr.dir.should eq(:outgoing)
    end

    it 'sets source_class' do
      dr = Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class)
      dr.source_class.should eq(person_class)
    end

    it 'to_s method works' do
      Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).to_s.should be_a(String)
    end
  end

  describe 'to' do

    context 'to(:friends)' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).to(:friends)
      end
      its(:dir) { should eq(:outgoing)}
      its(:rel_type) { should eq(:friends)}
      its(:target_name) { should be_nil}
      its(:source_class) { should eq(person_class)}
    end

    context 'to(Company)' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).to(company_class)
      end
      its(:dir) { should eq(:outgoing)}
      its(:rel_type) { should eq(:"#{person_class}#friends")}
      its(:target_name) { should eq(company_class.to_s)}
      its(:target_class) { should eq(company_class)}
      its(:source_class) { should eq(person_class)}
    end

    context 'to("Company")' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).to(company_class.to_s)
      end
      its(:dir) { should eq(:outgoing)}
      its(:rel_type) { should eq(:"#{person_class}#friends")}
      its(:target_name) { should eq(company_class.to_s)}
      its(:target_class) { should eq(company_class)}
      its(:source_class) { should eq(person_class)}
    end

    context 'to("Company", :knows)' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).to(company_class.to_s, :knows)
      end
      its(:dir) { should eq(:outgoing)}
      its(:rel_type) { should eq(:"#{person_class}#knows")}
      its(:target_name) { should eq(company_class.to_s)}
      its(:target_class) { should eq(company_class)}
      its(:source_class) { should eq(person_class)}
    end

    context 'to("Company#knows")' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).to("#{company_class.to_s}#knows")
      end
      its(:dir) { should eq(:outgoing)}
      its(:rel_type) { should eq(:"#{company_class}#knows")}
      its(:target_name) { should eq(company_class.to_s)}
      its(:target_class) { should eq(company_class)}
      its(:source_class) { should eq(person_class)}
    end

  end

  describe 'from' do
    context 'FileNode.has_one(:folder).from(:files)' do
      # FileNode.has_one(:folder).from(:files)  # will traverse any incoming relationship of type files
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:folder, true, files_class).from(:files)
      end
      its(:dir) { should eq(:incoming)}
      its(:rel_type) { should eq(:files)}
      its(:target_name) { should be_nil}
      its(:target_class) { should be_nil}
      its(:source_class) { should eq(files_class)}
    end

    context 'FileNode.has_one(:folder).from(Folder, :files)' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:folder, true, files_class).from(folder_class, :files)
      end
      its(:dir) { should eq(:incoming)}
      its(:rel_type) { should eq(:"#{folder_class}#files")}
      its(:target_name) { should eq(folder_class.to_s)}
      its(:target_class) { should eq(folder_class)}
      its(:source_class) { should eq(files_class)}
    end

    context 'from(:friends)' do
      subject do
        Neo4j::ActiveNode::HasN::DeclRel.new(:friends, false, person_class).from(:friends)
      end
      its(:dir) { should eq(:incoming)}
      its(:rel_type) { should eq(:friends)}
      its(:target_name) { should be_nil}
      its(:target_class) { should be_nil}
      its(:source_class) { should eq(person_class)}
    end

  end
end

