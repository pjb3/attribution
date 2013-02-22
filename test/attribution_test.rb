require 'test/unit'
require 'attribution'

class Book
  include Attribution

  integer :id
  string :title
  decimal :price
  date :published_on
  boolean :ebook_available
  boolean :used
  float :shipping_weight
  time :created_at
  time :updated_at
  time_zone :time_zone

  has_many :chapters
end

class Chapter
  include Attribution

  integer :number
  string :title
  integer :page_number

  belongs_to :book
end

class AttributionTest < Test::Unit::TestCase

  def test_create
    data = {
      :id => 1,
      :title => "Rework",
      :price => "22.00",
      :published_on => "March 9, 2010",
      :ebook_available => "yes",
      :used => "no",
      :shipping_weight => "14.4",
      :created_at => "2013-02-20 05:39:45 -0500",
      :updated_at => "2013-02-20T05:40:37-05:00",
      :time_zone => "Eastern Time (US & Canada)",
      :chapters => [
        {
          :number => "1",
          :title => "Introduction",
          :page_number => "1"
        }, {
          :number => "2",
          :title => "Takedowns",
          :page_number => "7"
        }, {
          :number => "3",
          :title => "Go",
          :page_number => "29"
        }
      ]
    }

    book = Book.new(data.to_json)

    assert_equal 1, book.id
    assert_equal "Rework", book.title
    assert_equal BigDecimal.new("22.00"), book.price
    assert_equal BigDecimal, book.price.class
    assert_equal Date.new(2010, 3, 9), book.published_on
    assert_equal true, book.ebook_available
    assert_equal true, book.ebook_available?
    assert_equal false, book.used
    assert_equal false, book.used?
    assert_equal 14.4, book.shipping_weight
    assert_equal Float, book.shipping_weight.class
    assert_equal Time.parse("2013-02-20T05:39:45-05:00"), book.created_at
    assert_equal Time.parse("2013-02-20T05:40:37-05:00"), book.updated_at
    assert_equal ActiveSupport::TimeZone["Eastern Time (US & Canada)"], book.time_zone
    assert_equal 1, book.chapters.first.number
    assert_equal 3, book.chapters.size
    assert_equal book, book.chapters.first.book
  end
end
