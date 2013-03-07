require 'test/unit'
require 'attribution'

#TODO: support using a different class name than the association name
class Author
  include Attribution

  integer :id
  string :first_name
  string :last_name

  has_many :books
end

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

  belongs_to :book
  has_many :chapters
end

class Chapter
  include Attribution

  integer :id
  integer :number, :required => true, :doc => "Starts from 1"
  string :title
  integer :page_number

  belongs_to :book
  has_many :pages
end

class Page
  include Attribution

  integer :id
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

  def test_attributes
    chapter = Chapter.new(:number => "1")
    assert_equal [
      { :name => :id, :type => :integer },
      { :name => :number, :type => :integer, :required => true, :doc => "Starts from 1" },
      { :name => :title, :type => :string },
      { :name => :page_number, :type => :integer },
      { :name => :book_id, :type => :integer }
    ], Chapter.attributes
    assert_equal({ :id => nil, :number => 1, :title => nil, :page_number => nil, :book_id => nil }, chapter.attributes)
  end

  def test_date_hash
    book = Book.new(:published_on => { :year => '2013', :month => '03', :day => '17' })
    assert_equal Date.parse('2013-03-17'), book.published_on
  end

  def test_date_hash_just_year
    book = Book.new(:published_on => { :year => '2013', :month => '', :day => '' })
    assert_equal Date.new(2013), book.published_on
  end

  def test_date_hash_just_year_month
    book = Book.new(:published_on => { :year => '2013', :month => '5', :day => '' })
    assert_equal Date.new(2013, 5), book.published_on
  end

  def test_date_hash_empty
    book = Book.new(:published_on => { :year => '', :month => '', :day => '' })
    assert_equal nil, book.published_on
  end

  def test_time_hash
    book = Book.new(:created_at => { :year => '2013', :month => '03', :day => '17', :hour => '07', :min => '30', :sec => '11', :utc_offset => '3600' })
    assert_equal Time.parse('2013-03-17 07:30:11 +01:00'), book.created_at
  end

  def test_time_hash_empty
    book = Book.new(:created_at => { :year => '', :month => '', :day => '', :hour => '', :min => '', :sec => '', :utc_offset => '' })
    assert_equal nil, book.created_at
  end

  def test_time_hash_just_year
    book = Book.new(:created_at => { :year => '2013' })
    assert_equal Time.parse('2013-01-01 00:00:00'), book.created_at
  end

  def test_time_hash_just_year_month
    book = Book.new(:created_at => { :year => '2013', :month => '03' })
    assert_equal Time.parse('2013-03-01 00:00:00'), book.created_at
  end

  def test_time_hash_just_year_month_day
    book = Book.new(:created_at => { :year => '2013', :month => '03', :day => '17' })
    assert_equal Time.parse('2013-03-17 00:00:00'), book.created_at
  end

  def test_nil
    book = Book.new(
      :id => nil,
      :title => nil,
      :price => nil,
      :published_on => nil,
      :ebook_available => nil,
      :used => nil,
      :shipping_weight => nil,
      :created_at => nil,
      :time_zone => nil,
    )
    assert_equal nil, book.id
    assert_equal nil, book.title
    assert_equal nil, book.price
    assert_equal nil, book.published_on
    assert_equal nil, book.ebook_available
    assert_equal nil, book.used
    assert_equal nil, book.shipping_weight
    assert_equal nil, book.created_at
    assert_equal nil, book.time_zone
  end
end
