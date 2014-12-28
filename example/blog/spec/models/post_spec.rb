require 'rails_helper'

RSpec.describe Post, type: :model do
  it 'will run the test with a empty database' do
    ruby = Post.create!(title: 'Ruby')
    expect(ruby.title).to eq('Ruby')
    expect(Post.count).to eq(1)
  end

end