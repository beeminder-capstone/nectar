=begin
 * Created by PSU Beeminder Capstone Team on 3/12/2017.
 * Copyright (c) 2017 PSU Beeminder Capstone Team
 * This code is available under the "MIT License".
 * Please see the file LICENSE in this distribution for license terms.
=end
PROVIDERS.fetch(:beeminder).register_metric :compose_goals do |metric|
  metric.description =
    "Combine multiple goals into one by providing a factor for each goal." \
    "Each datapoint from a source goal will be multiplied by the factor " \
    "and sent to target goal."
  metric.title = "Compose goals"
  slug_key = "source_slugs"

  metric.block = proc do |adapter, options|
    Array(options[slug_key]).flat_map do |slug, factor|
      next [] if factor.blank?
      adapter.recent_datapoints(slug).map do |dp|
        value = dp.value * Float(factor)
        [
          dp.timestamp.utc,
          value,
          "#{slug}: #{value.round(2)}",
        ]
      end
    end.group_by(&:first).map do |ts, entries|
      Datapoint.new(
        unique: true,
        timestamp: ts,
        value: entries.sum(&:second),
        comment_prefix: entries.map(&:third).join(",")
      )
    end
  end

  metric.param_errors = proc do |params|
    slugs = params[slug_key]
    if slugs.is_a?(Hash)
      errors = []

      valid_factors = slugs.values.reject(&:blank?).all? do |factor|
        begin
          Float(factor)
        rescue ArgumentError
          false
        end
      end
      valid_slugs = slugs.keys.all? do |key|
        key.is_a?(String) && key.length <= BeeminderAdapter::MAX_SLUG_LENGNTH
      end

      errors << "All factors must be numbers" unless valid_factors

      errors << "Slug too long" unless valid_slugs

      errors
    else
      ["Must provide #{slug_key} hash"]
    end
  end
end
