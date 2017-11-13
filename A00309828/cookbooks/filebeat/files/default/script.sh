sudo yum install java -y

sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

echo '[elastic-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md' > /etc/yum.repos.d/elastic.repo

sudo yum install filebeat -y
