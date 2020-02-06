describe Neo4j::ActiveNode do
  before(:each) do
    create_index :StoredFile, :type, type: :exact
    create_index :StoredFile, :size, type: :exact
    create_index :StoredFile, :flag, type: :exact
    stub_active_node_class('StoredFile') do
      enum type: [:unknown, :image, :video], _default: :unknown
      enum size: {big: 100, medium: 7, small: 2}, _prefix: :dimension
      enum flag: [:clean, :dangerous], _suffix: true
      enum type_format: [:Mpeg, :Png], _case_sensitive: true, _index: false

      has_one :in, :uploader, rel_class: :UploaderRel
    end

    stub_active_node_class('User') do
      has_many :out, :files, rel_class: :UploaderRel
    end

    stub_active_rel_class('UploaderRel') do
      from_class :User
      to_class :StoredFile
      type 'uploaded'

      enum origin: [:disk, :web]
    end
  end

  describe 'ClassMethods' do
    it 'lists all types and sizes' do
      expect(StoredFile.types).to eq(unknown: 0, image: 1, video: 2)
      expect(StoredFile.sizes).to eq(big: 100, medium: 7, small: 2)
      expect(StoredFile.flags).to eq(clean: 0, dangerous: 1)
      expect(StoredFile.type_formats).to eq(Mpeg: 0, Png: 1)
      expect(UploaderRel.origins).to eq(disk: 0, web: 1)
    end

    it 'respects _index = false option' do
      expect { StoredFile.as(:f).pluck('f.type_format') }.to_not raise_error
    end

    it 'raises error if keys are invalid' do
      expect { StoredFile.enum something: [:value1, :Value1] }.to raise_error(ArgumentError)
    end

    it "raises error if _default option doesn't match key" do
      expect { StoredFile.enum something: [:value1, :value2], _default: :value3 }.to raise_error(ArgumentError)
    end
  end

  describe 'getters and setters' do
    it 'returns nil by default' do
      file = StoredFile.new
      expect(file.flag).to be_nil
    end

    it 'returns the default value' do
      file = StoredFile.new
      expect(file.type).to eq(:unknown)
    end

    it 'assigns using types' do
      file = StoredFile.new
      file.type = :video
      expect(file.type).to eq(:video)
    end

    it 'gets serialized correctly as integer' do
      file = StoredFile.new
      file.type = :video
      file.save!
      expect(StoredFile.as(:f).pluck('f.type')).to eq([2])
      expect(file.reload.type).to eq(:video)
    end

    it 'accepts nil as value' do
      file = StoredFile.new
      file.flag = nil
      file.save!
      expect(StoredFile.as(:f).where(id: file.id).pluck('f.flag')).to eq([nil])
      expect(file.reload.flag).to eq(nil)
    end

    it "raises error if value doesn't match an enum key" do
      file = StoredFile.new
      file.type = :audio
      expect { file.save! }.to raise_error(
        Neo4j::Shared::Enum::InvalidEnumValueError,
        'Case-insensitive (downcased) value passed to an enum property must match one of the enum keys'
      )
    end

    it 'respects local _case_sensitive option' do
      file = StoredFile.new
      file.type_format = :png
      expect { file.save! }.to raise_error(Neo4j::Shared::Enum::InvalidEnumValueError, 'Value passed to an enum property must match one of the enum keys')

      file.type_format = :Png
      file.save!
      expect(StoredFile.as(:f).pluck('f.type_format')).to eq([1])
      expect(file.reload.type_format).to eq(:Png)
    end

    it 'respects global _case_sensitive = false default' do
      file = StoredFile.new
      file.type = :VIdeO
      file.save!
      expect(StoredFile.as(:f).pluck('f.type')).to eq([2])
      expect(file.reload.type).to eq(:video)
    end

    context 'global enums_case_sensitive config is set to true' do
      let_config(:enums_case_sensitive, true) do
        it 'respects global _case_sensitive = true default' do
          file = StoredFile.new
          file.type = :VIdeO
          expect { file.save! }.to raise_error(Neo4j::Shared::Enum::InvalidEnumValueError, 'Value passed to an enum property must match one of the enum keys')
        end

        it 'still accepts valid params' do
          file = StoredFile.new
          file.type = :video
          file.save!
          expect(StoredFile.as(:f).pluck('f.type')).to eq([2])
          expect(file.reload.type).to eq(:video)
        end
      end
    end
  end

  describe 'scopes' do
    it 'finds elements by enum key' do
      file1 = StoredFile.create!(type: :unknown)
      file2 = StoredFile.create!(type: :video)
      ids = StoredFile.video.map(&:id)
      expect(ids).not_to include(file1.id)
      expect(ids).to include(file2.id)
    end
  end

  describe '#where' do
    it '(type: :video) finds elements by enum key' do
      file1 = StoredFile.create!(type: :unknown)
      file2 = StoredFile.create!(type: :video)
      ids = StoredFile.where(type: :video).pluck(:id)
      expect(ids).not_to include(file1.id)
      expect(ids).to include(file2.id)
    end

    it '(type: [:unknown, :video]) finds elements matching the provided enum keys' do
      file1 = StoredFile.create!(type: :unknown)
      file2 = StoredFile.create!(type: :video)
      file3 = StoredFile.create!(type: :image)
      ids = StoredFile.where(type: [:unknown, :video]).pluck(:id)
      expect(ids).to include(file1.id)
      expect(ids).to include(file2.id)
      expect(ids).to_not include(file3.id)
    end
  end

  describe '#rel_where' do
    it 'finds relations matching given enum key' do
      user = User.create!
      file = StoredFile.create!
      file2 = StoredFile.create!
      UploaderRel.create!(from_node: user, to_node: file, origin: :web)
      UploaderRel.create!(from_node: user, to_node: file2, origin: :disk)
      expect(user.files(:f).rel_where(origin: :web).pluck(:id)).to contain_exactly(file.id)
    end
  end

  describe '? methods' do
    it 'returns false when accessing to a nil value' do
      file = StoredFile.new
      expect(file).not_to be_clean_flag
      expect(file).not_to be_dangerous_flag
    end

    it 'returns true when the enum is in the current state' do
      file = StoredFile.new
      file.type = :video
      expect(file).to be_video
    end

    it 'returns false when the enum is in the current state' do
      file = StoredFile.new
      file.type = :image
      expect(file).not_to be_video
    end

    it 'returns true when the enum is in the current state (with prefix)' do
      file = StoredFile.new
      file.size = :big
      expect(file).to be_dimension_big
    end

    it 'returns true when the enum is in the current state (with prefix)' do
      file = StoredFile.new
      file.size = :small
      expect(file).not_to be_dimension_big
    end

    it 'returns true when the enum is in the current state (with prefix)' do
      file = StoredFile.new
      file.flag = :dangerous
      expect(file).to be_dangerous_flag
    end

    it 'returns false when the enum is not in the current state (with prefix)' do
      file = StoredFile.new
      file.flag = :dangerous
      expect(file).not_to be_clean_flag
    end
  end

  describe '! methods' do
    it 'sets to a state' do
      file = StoredFile.new
      file.video!
      expect(file.type).to eq(:video)
    end

    it 'sets to a state (with prefix)' do
      file = StoredFile.new
      file.dimension_big!
      expect(file.size).to eq(:big)
    end

    it 'sets to a state (with suffix)' do
      file = StoredFile.new
      file.dangerous_flag!
      expect(file.flag).to eq(:dangerous)
    end
  end

  describe 'conflicts' do
    it 'raises an error when two enums are conflicting' do
      create_index :ConflictingModel, :enum1, type: :exact
      create_index :ConflictingModel, :enum2, type: :exact

      expect do
        stub_active_node_class('ConflictingModel') do
          enum enum1: [:a, :b, :c]
          enum enum2: [:c, :d]
        end
      end.to raise_error(Neo4j::Shared::Enum::ConflictingEnumMethodError)
    end
  end

  context 'when using `ActionController::Parameters`' do
    let(:params) { action_controller_params('type' => 'image').permit! }
    it 'assigns enums correctly when instancing a new class' do
      file = StoredFile.new(params)
      expect(file.type).to eq('image')
    end

    it 'assigns enums correctly when assigning to `attributes`' do
      file = StoredFile.new
      file.attributes = params
      expect(file.type).to eq('image')
    end
  end

  describe 'required index behavior' do
    before do
      create_index(:Incomplete, :foo, type: :exact)
      stub_active_node_class('Incomplete') do
        enum foo: [:a, :b]
        enum bar: [:c, :d]
      end
    end

    it_behaves_like 'raises schema error not including', :index, :Incomplete, :foo
    it_behaves_like 'raises schema error including', :index, :Incomplete, :bar

    context 'second enum index created' do
      before { create_index(:Incomplete, :bar, type: :exact) }

      it_behaves_like 'does not raise schema error', :Incomplete
      it_behaves_like 'does not log schema option warning', :index, :Incomplete
    end
  end
end
