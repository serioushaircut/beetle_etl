module BeetleETL
  class Load < Step

    IMPORTER_COLUMNS = %i[
      external_source
      transition
    ]

    def initialize(table_name, relations)
      super(table_name)
      @relations = relations
    end

    def run
      %w(create update delete).each do |transition|
        public_send(:"load_#{transition}")
      end
    end

    def dependencies
      @relations.values.map { |d| Load.step_name(d) }.to_set
    end

    def load_create
      just_now = now

      database.execute <<-SQL
        INSERT INTO #{target_table_name_sql}
          (#{data_columns.join(', ')}, external_source, created_at, updated_at)
        SELECT
          #{data_columns.join(', ')},
          '#{external_source}',
          '#{just_now}',
          '#{just_now}'
        FROM #{stage_table_name_sql}
        WHERE transition = 'CREATE'
      SQL
    end

    def load_update
      database.execute <<-SQL
        UPDATE #{target_table_name_sql} target
        SET
          #{updatable_columns.map { |c| %Q("#{c}" = stage."#{c}") }.join(',')},
          "updated_at" = '#{now}',
          deleted_at = NULL
        FROM #{stage_table_name_sql} stage
        WHERE stage.id = target.id
          AND stage.transition IN ('UPDATE', 'REINSTATE')
      SQL
    end

    def load_delete
      just_now = now

      database.execute <<-SQL
        UPDATE #{target_table_name_sql} target
        SET
          updated_at = '#{just_now}',
          deleted_at = '#{just_now}'
        FROM #{stage_table_name_sql} stage
        WHERE stage.id = target.id
          AND stage.transition = 'DELETE'
      SQL
    end

    private

    def data_columns
      table_columns - ignored_columns
    end

    def table_columns
      @table_columns ||= database[stage_table_name.to_sym].columns
    end

    def ignored_columns
      IMPORTER_COLUMNS + table_columns.select do |column_name|
        column_name.to_s.index(/^external_.+_id$/)
      end
    end

    def updatable_columns
      data_columns - [:id, :external_source, :external_id]
    end

    def now
      Time.now
    end

  end
end
