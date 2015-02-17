module BeetleETL
  class TransformationLoader

    def initialize
      @transformations = []
      @helper_definitions = nil
    end

    def load
      File.open(BeetleETL.config.transformation_file, 'r') do |file|
        instance_eval file.read
      end

      @transformations.map do |(table_name, setup)|
        Transformation.new(table_name, setup, @helper_definitions)
      end
    end

    private

    def import(table_name, &setup)
      @transformations << [table_name, setup]
    end

    def helpers(&helper_definitions)
      @helper_definitions = helper_definitions
    end

  end
end
