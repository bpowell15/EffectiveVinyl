require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns

    return @columns if @columns
    columns = DBConnection.execute2(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL

    @columns = columns.first.map!(&:to_sym)
  end

  def self.finalize!
  self.columns.each do |name|
    define_method(name) do
      self.attributes[name]
    end

    define_method("#{name}=") do |value|
      self.attributes[name] = value
    end
  end
end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    "#{self.to_s}s".tableize
  end

  def self.all
    instances = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL

    parse_all(instances)
  end

  def self.parse_all(results)
    all_instances = []
    results.each do |instance|
       all_instances << self.new(instance)
      # self.inst_var = value
    end
    all_instances
  end

  def self.find(id)
    instance = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    return nil if instance.empty?
    self.new(instance.first)

  end


  def initialize(params = {})
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym
      if self.class.columns.include?(attr_sym)
        self.send("#{attr_sym}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    self.class.columns.map {|attr| self.send(attr)}
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = []
    attribute_values.drop(1).length.times { question_marks << '?'}
    question_marks = question_marks.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.drop(1).map!{ |attr_name| "#{attr_name} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1), self.id)
    UPDATE
        #{self.class.table_name}
    SET
       #{col_names}
    WHERE
      id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
