require 'spec_helper'

describe Prelude do
  it 'should have a version' do
    expect(Prelude::VERSION).to_not be_nil
  end

  it 'should be able to call preloaders on a single instance' do
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number) do |records|
        Hash.new { |h, k| h[k] = 42 } # answer is always 42
      end
    end

    expect(klass.new.number).to eq(42)
  end

  it 'should be able to batch multiple calls into one' do
    call_count = 0

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number) do |records|
        call_count += 1
        Hash[records.map { |r| [r, 42] }]  # answer is always 42
      end
    end

    5.times { klass.create! }

    expect(klass.all.with_prelude.map(&:number).uniq).to eq([42]) # all the same result
    expect(call_count).to eq(1) # only one call
  end

  it 'should be able to work with Arrays' do
    call_count = 0

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number) do |records|
        call_count += 1
        Hash.new { |h, k| h[k] = 42 } # answer is always 42
      end
    end

    records = 5.times.map { klass.new }
    numbers = records.map.with_prelude(&:number)

    expect(numbers.uniq).to eq([42]) # all the same result
    expect(call_count).to eq(1) # only one call
  end

  it 'should be able to chain Enumerators' do
    call_count = 0

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number) do |records|
        call_count += 1
        Hash.new { |h, k| h[k] = 42 } # answer is always 42
      end
    end

    records = 5.times.map { klass.new }
    numbers = records.map.with_prelude.with_index do |record, i|
      expect(record).to be_present
      expect(i).to be_a(Integer)
      record.number
    end

    expect(numbers.uniq).to eq([42]) # all the same result
    expect(call_count).to eq(1) # only one call
  end

  it 'should raise an error if there is a type mismatch in the Array' do
    expect {
      [1, "two"].each.with_prelude.to_a
    }.to raise_error(Prelude::Enumerator::TypeMismatch)
  end

  it 'should memoize when called on a single item' do
    call_count = 0

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number) do |records|
        call_count += 1
        Hash.new { |h, k| h[k] = 42 } # answer is always 42
      end
    end

    record = klass.new
    numbers = 5.times.map { record.number }

    expect(numbers.uniq).to eq([42]) # all the same result
    expect(call_count).to eq(1) # only one call
  end

  it 'should be able to pass arguments to methods' do
    call_arguments = []

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:multiply_by) do |records, by|
        call_arguments << [records.to_a, by]
        Hash.new { |h, k| h[k] = 42 * by }
      end
    end

    instances = 3.times.map { klass.new }

    instances.each.with_prelude do |i|
      expect(i.multiply_by(1)).to eq(42)
      expect(i.multiply_by(1)).to eq(42)
      expect(i.multiply_by(2)).to eq(84)
    end

    # two calls with the appropriate arguments
    expect(call_arguments).to eq([
      [instances, 1], # deduped
      [instances, 2]
    ])
  end

  it 'should be able to set a batch size' do
    call_count = 0

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number, batch_size: 2) do |records|
        call_count += 1
        Hash[records.map { |r| [r, 42] }]
      end
    end

    values = 4.times.map { klass.new }.map.with_prelude { |r| r.number }

    expect(values.uniq).to eq([42])
    expect(call_count).to eq(4 / 2) # one per batch
  end

  it 'should be able to use batch_size with default_proc' do
    call_count = 0

    klass = Class.new(ActiveRecord::Base) do
      self.table_name = 'breweries'

      define_prelude(:number, batch_size: 2) do |records|
        call_count += 1
        Hash.new { |h, k| h[k] = 42 }
      end
    end

    values = 4.times.map { klass.new }.map.with_prelude { |r| r.number }

    expect(values.uniq).to eq([42])
    expect(call_count).to eq(4 / 2) # one per batch
  end
end
