require_relative 'db_connection'
require_relative 'sql_object'

module Searchable
  def where(params)
    where_line = params.map {|param, values| "#{param} = ?"}.join(" AND ")
    param_values = params.values
    search = DBConnection.execute(<<-SQL, param_values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL

    parse_all(search)

  end
end

class SQLObject
  extend Searchable
end
