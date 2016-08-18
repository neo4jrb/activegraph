describe Neo4j::ActiveNode do
  before(:each) do
    stub_active_node_class('StoredFile') do
      enum type: [:unknown, :image, :video], _default: :unknown
      enum size: {big: 100, medium: 7, small: 2}, _prefix: :dimension
      enum flag: [:clean, :dangerous], _suffix: true

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
      expect(UploaderRel.origins).to eq(disk: 0, web: 1)
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
      ids = StoredFile.where(type: :video).pluck(:uuid)
      expect(ids).not_to include(file1.id)
      expect(ids).to include(file2.id)
    end

    it '(type: [:unknown, :video]) finds elements matching the provided enum keys' do
      file1 = StoredFile.create!(type: :unknown)
      file2 = StoredFile.create!(type: :video)
      file3 = StoredFile.create!(type: :image)
      ids = StoredFile.where(type: [:unknown, :video]).pluck(:uuid)
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
      expect(user.files(:f).rel_where(origin: :web).pluck(:uuid)).to contain_exactly(file.id)
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
      expect do
        stub_active_node_class('ConflictingModel') do
          enum enum1: [:a, :b, :c]
          enum enum2: [:c, :d]
        end
      end.to raise_error(Neo4j::Shared::Enum::ConflictingEnumMethodError)
    end
  end
end
