module Stream
  module Rankable
    attr_writer :ranks

    def ranks
       @ranks ||= Hash.new
       @ranks
    end

    def rank!(ranker_id, rank_value)
      raise ArgumentError, "Rankable#rank! rank_value must be a number from 0 to 1" unless (0..1.0).cover?(rank_value)
      ranks[ranker_id] = rank_value
    end

    def total_rank
      # OPTIMIZE: handcode to return 0 early when finding a 0 value
      return 0 if delete? || ranks.empty?
      ranks.values.reduce(:+)
    end

    def delete!(ranker_id)
      raise ArgumentError, "Rankable#delete! trying to delete ranker_id #{ranker_id} before it exists" unless ranks[ranker_id]
      ranks[ranker_id] = nil
    end

    def delete?
      return false unless ranks
      # TODO: lock for writing
      should_delete = ranks.any? { |rank_id, rank_value| rank_value.nil? }
      # TODO: unlock for writing
      should_delete
    end
  end
end