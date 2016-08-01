classes = %w(
  CreditsExpirerWorseOfAll
  CreditsExpirerWorse
  CreditsExpirer
  CreditsExpirerOneQuery
  CreditsExpirerOneQueryCte
)

classes.each do |klass|
  puts
  puts "==== Running benchmark for '#{klass}' ===="

  system "ruby benchmark.rb #{klass}"

  puts
  puts '--------------------------------------------------------------'
end
