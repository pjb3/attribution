require 'test_helper'
require 'attribution/model'

class Article
  include Attribution::Model

  string :title, required: true, format: { with: /\A\w/, message: "must start with a letter" }, length: 4..20
end

class AttributionModelTest < Test::Unit::TestCase
  def test_model
    article = Article.new(id: 1, created_at: Time.now, updated_at: Time.now)
    assert !article.valid?
    assert_equal ["can't be blank", "must start with a letter", "is too short (minimum is 4 characters)"], article.errors[:title]
  end
end
