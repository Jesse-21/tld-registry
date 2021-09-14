class ObjectCountValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    min, max = options[:min].call, options[:max].call
    values = value.reject(&:marked_for_destruction?)

    return if values.size.between?(min, max)
    association = options[:association] || attribute
    record.errors.add(association, :out_of_range, **{ min: min, max: max })
  end
end
