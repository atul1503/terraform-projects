#!/bin/bash

echo "start of init script"
cd /home/ec2-user
yum install -y git
yum install -y pip
git clone "https://github.com/macloo/basic-flask-app.git"
cd basic-flask-app
pip install -r requirements.txt
sed -i "s/app.run(debug=True)/app.run(host=\"0.0.0.0\",debug=True)/g" routes.py
python routes.py