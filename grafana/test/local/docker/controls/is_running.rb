control 'is_running' do
  impact 1.0
  title 'Grafana is running and serving HTTP requests'

  describe port(3000) do
   it { should be_listening }
 end

# todo we may need to use a property to pass the URL
 describe http('http://localhost:3000/login') do
   its('status') { should cmp 200 }
   its('headers.Content-Type') { should cmp 'text/html; charset=UTF-8' }
   its('body') {should match /Grafana/}
 end

end
