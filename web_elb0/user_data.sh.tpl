#!/bin/bash
apt-get update
apt-get -y install nginx


WebServerIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

cat <<EOF > /var/www/html/index.html
<html>
<body bgcolor=#031C5F>
<h2><font color="yellow">Project Name: ${project_name} </font></h2><br><p>
<h2><font color="red">  Built in Terraform v0.12 </font></h2><br><p>
<font color="white">Server Private IP =: <font color="aqua">$WebServerIP<br><br>
<font color="pink">
<b>Version 1.0</b>
</body>
</html>
EOF


systemctl restart nginx
systemctl enable nginx
