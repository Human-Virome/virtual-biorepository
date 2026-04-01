
## Purpose

This repository contains the Human Virome Project's Virtual Biorepository website.

This website offers a centralized and standardized process for coordinating
centers to upload sample metadata. It also generates files from this metadata to
be used in submitting sequencing reads to SRA.


## Implementation

The website is hosted on Amazon Web Services Elastic Compute Cluster (AWS EC2). 
It was set up as follows:


In AWS IAM, create a policy for sending emails and managing backups.



```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail", "ses:SendRawEmail"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::jplab-backups"],
      "Condition": {
        "StringEquals": {
          "s3:prefix": ["", "hvp/"],
          "s3:delimiter": ["/"] }}
		},
		{
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::jplab-backups/hvp/*"]
		}
  ]
}
```

In AWS IAM, create an EC2 role with the above policy (ec2_hvp_role).




Launch and instance -> Quick start

* Amazon Machine Image = Ubuntu Server 24.04 LTS (ami-020cba7c55df1f615)
* Security group = ports 22, 80, 443, and 3306
* Storage = 20 GiB
* Advanced details -> IAM instance profile = ec2_hvp_role


Connect to the instance and run:

```bash
sudo bash
apt-get update

snap install aws-cli --classic
apt-get install -y apache2 libapache2-mod-r-base mysql-server libssl-dev libmysqlclient-dev libicu-dev
R -e "install.packages(c('bcrypt', 'DBI', 'jsonlite', 'openssl', 'openxlsx2', 'RMariaDB'))"

git clone https://github.com/Human-Virome/virtual-biorepository.git /var/www/hvp
git config --global --add safe.directory /var/www/hvp
chown -R www-data:www-data /var/www/hvp
ln -s /var/www/hvp/config/httpd.conf /etc/apache2/sites-enabled/hvp.conf
mysql -u root < /var/www/hvp/config/database.sql

echo "www-data ALL=(root) NOPASSWD:/usr/sbin/apache2ctl" > /etc/sudoers.d/hvp
a2dissite 000-default
a2enmod md
a2enmod ssl
systemctl daemon-reload
systemctl restart apache2
```


Test email sending from command line on EC2.
```r
aws ses send-email --from hvp@jplab.net --to dpsmith@bcm.edu --subject Hello --text "test email"
```
