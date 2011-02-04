module ActiveRecord
  module ConnectionAdapters
    class MysqlAdapter
      StoredRoutine = Struct.new(:body)

      def stored_functions
        results = execute("SHOW FUNCTION STATUS WHERE db ='#{current_database}'")
        names = []
        results.each { |row| names << row[1] }
        results.free
        names
      end

      def remove_stored_function(stored_function_name)
        execute("DROP FUNCTION IF EXISTS #{stored_function_name}")
      end

      def create_stored_function(stored_function_name, options = {}) #:nodoc:
        function = StoredRoutine.new
        yield(function)
        remove_stored_procedure(stored_function_name)
        execute(function.body)
      end

      def stored_procedures
        results = execute("SHOW PROCEDURE STATUS WHERE db ='#{current_database}'")
        names = []
        results.each { |row| names << row[1] }
        results.free
        names
      end

      def remove_stored_procedure(stored_procedure_name)
        execute("DROP PROCEDURE IF EXISTS #{stored_procedure_name}")
      end

      def create_stored_procedure(stored_procedure_name, options = {}) #:nodoc:
        procedure = StoredRoutine.new
        yield(procedure)
        remove_stored_procedure(stored_procedure_name)
        execute(procedure.body)
      end

      def select_sp(sql, name = nil)
        result = execute(sql)
        return nil unless result
        rows = result.all_hashes
        result.free
        if result
          while @connection.more_results
            @connection.next_result
            begin
              next_result = @connection.use_result
              rows << next_result.all_hashes
              next_result.free
            rescue Mysql::Error => e
              # The final result from the procedure is a status result that includes no result set.
              # The status indicates whether the procedure succeeded or an error occurred.
            end
          end
        end
        rows
      end
    end
  end
end