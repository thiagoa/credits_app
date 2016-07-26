require 'pathname'
require Pathname(__dir__).join('config', 'environment')

DATE_RANGE = Date.new(2013, 12, 15)..Date.new(2014, 5, 15)
SUBJECT_CLASS = ARGV[0].constantize

def cleanup!
  reversal_credits.delete_all
  credits_with_expiration.update_all(processed: false)
end

def reversal_credits
  Credit.where(type: 'Reversal')
end

def credits_with_expiration
  Credit.where(expires_at: DATE_RANGE)
end

def max_runtime(stats)
  stats.max_by { |v| v[1] }.reverse.join(' - ')
end

def min_runtime(stats)
  stats.min_by { |v| v[1] }.reverse.join(' - ')
end

def avg_runtime(stats)
  stats.sum { |v| v[1] } / stats.count
end

stats = DATE_RANGE.each.with_object({}) do |date, memo|
  puts

  results = Benchmark.bm do |x|
    x.report(date) { SUBJECT_CLASS.call(date) }
  end

  memo[date] = results[0].real
end

puts "Max day runtime: #{max_runtime(stats)}"
puts "Min day runtime: #{min_runtime(stats)}"
puts "Avg runtime: #{avg_runtime(stats)}"
puts "Number of reversal credits created: #{reversal_credits.count}"

cleanup!
