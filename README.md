# Attribution

Attribution is a gem to allow you to define attributes for a Ruby object so that getters and setters will be defined that handle typecasting.  It also allows you to define associations between objects in an [ActiveRecord-style way][ar].

## Installation

Add this line to your application's Gemfile:

    gem 'attribution'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install attribution

## Usage

You can define attributes like this:

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

And then you can pass in a Hash or a String of JSON to initialize the object:

    json = %{{
      "id": 1,
      "title": "Rework",
      "price": "22.00",
      "published_on": "March 9, 2010",
      "ebook_available": "yes",
      "used": "no",
      "shipping_weight": "14.4",
      "created_at": "2013-02-20 05:39:45 -0500",
      "updated_at": "2013-02-20T05:40:37-05:00",
      "time_zone": "Eastern Time (US & Canada)",
      "chapters": [
        {
          "number": "1",
          "title": "Introduction",
          "page_number": "1"
        },
        {
          "number": "2",
          "title": "Takedowns",
          "page_number": "7"
        },
        {
          "number": "3",
          "title": "Go",
          "page_number": "29"
        }
      ]
    }}
    
    book = Book.new(json)

The object is populated based on the data, the values are converted into the type defined by the attribute:

    >> book.id
    => 1
    >> book.title
    => "Rework"
    >> book.price
    => #<BigDecimal:7f82dfe9d018,'0.22E2',9(18)>
    >> book.published_on
    => Tue, 09 Mar 2010
    >> book.ebook_available?
    => true
    >> book.used?
    => false
    >> book.shipping_weight
    => 14.4
    >> book.created_at
    => 2013-02-20 05:39:45 -0500
    >> book.updated_at
    => 2013-02-20 05:40:37 -0500
    >> book.time_zone
    => GMT-05:00 Eastern Time US  Canada

Also, the association is populated with an array of objects:

    >> book.chapters.size
    => 3
    >> book.chapters[2].page_number
    => 29

The reciprocating association is populated as well:

    >> book.chapters[2].book.title
    => "Rework"

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[ar]: http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html