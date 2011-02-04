module ActiveRecord
  class SchemaDumper
    def stored_function(stored_function, stream)
      begin
        result = @connection.execute("SHOW CREATE FUNCTION #{stored_function}")
        create_stmt = String.new
        result.each { |r| create_stmt << r[2] }
        create_stmt.gsub!('\t', '  ')
        create_stmt.gsub!(/DEFINER=`[^`]*`@`[^`]*` /, '')

        pro = StringIO.new
        pro.print "  create_stored_function #{stored_function.inspect}"
        pro.puts " do |p|"
        pro.puts "    p.body = <<-_SQL_"
        pro.puts "      #{create_stmt}"
        pro.puts "    _SQL_"
        pro.puts "  end"

        pro.rewind
        stream.print pro.read

      rescue => e
        stream.puts "# Could not routine #{stored_function.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end

      stream
    end

    def stored_procedure(stored_procedure, stream)
      begin

        result = @connection.execute("SHOW CREATE PROCEDURE #{stored_procedure}")
        create_stmt = String.new
        result.each { |r| create_stmt << r[2] }
        create_stmt.gsub!('\t', '  ')
        create_stmt.gsub!(/DEFINER=`[^`]*`@`[^`]*` /, '')

        pro = StringIO.new
        pro.print "  create_stored_procedure #{stored_procedure.inspect}"
        pro.puts " do |p|"
        pro.puts "    p.body = <<-_SQL_"
        pro.puts "      #{create_stmt}"
        pro.puts "    _SQL_"
        pro.puts "  end"

        pro.rewind
        stream.print pro.read

      rescue => e
        stream.puts "# Could not stored procedure #{stored_procedure.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end

      stream
    end

    def tables_with_stored_routines(stream)
      tables_without_stored_routines(stream)

      @connection.stored_procedures.each do |procedure|
        stored_procedure(procedure, stream)
      end

      @connection.stored_functions.each do |function|
        stored_function(function, stream)
      end
    end

    alias_method_chain :tables, :stored_routines
  end
end