#!/bin/bash

# Accept command line arguments for instance name and admin password
instance_name=$1
admin_password=$2

# Set the base port number
base_port_number=6000

# File to store the last used port number
##port_file="/home/kptevta/services/automatic_instances/instances/last_used_port.txt"
port_file="/home/javairia/Documents/ERISP/automatic_instances1st_change/instances/last_used_port.txt"
# If the file exists, read the last used port number
if [ -f "$port_file" ]; then
    port_number=$(cat "$port_file")
else
    port_number=$base_port_number
fi

# Function to check if a port is in use
check_port() {
    local port=$1
    lsof -i :$port >/dev/null 2>&1
}

# Find the next available port
while check_port "$port_number"; do
    ((port_number++))
done

# Print the result
echo "Selected Port: $port_number"

# Save the last used port number to the file
echo "$port_number" > "$port_file"

# Step 1: Change to the instances directory
##cd /home/kptevta/services/automatic_instances/instances
cd /home/javairia/Documents/ERISP/automatic_instances1st_change/instances
# Step 2: Create directory with provided instance name
if [ ! -d "$instance_name" ]; then
    mkdir "$instance_name"
fi

# Step 3: Change directory to the created instance directory
cd "$instance_name" || exit

# Step 4: Create required directories
mkdir -p data config log backups

# Step 5: Create docker-compose.yaml file
cat > docker-compose.yaml <<EOF
version: '3'
services:
  flectra:
    image: erispimages/business4x:v2.0
    container_name: $instance_name
    user: root
    mem_limit: 4g
    cpuset: "4"
    command: -- --dev=reload
    depends_on:
      - postgres
    links:
      - "postgres:db"
    ports:
      - "$port_number:7073"
    restart: always
    networks:
      net-erisp:
        aliases:
          - $instance_name
    volumes:
      - data:/var/lib/flectra
      - config:/etc/flectra
      - log:/var/log/flectra
      - ./extra-addons:/mnt/extra-addons
      - backups:/opt/flectra/backups
    logging:
      options:
        max-size: "10m"
        max-file: "3"
  
  postgres:
    image: postgres:10.0
    container_name: postgres-$instance_name
    environment:
      - POSTGRES_PASSWORD=flectra
      - POSTGRES_USER=flectra
      - PGDATA=/var/lib/postgresql/data/pgdata
    restart: always
    volumes:
      - ./postgres:/var/lib/postgresql/data/pgdata
    logging:
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - net-erisp


volumes:
  data:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: \$PWD/data
  config:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: \$PWD/config
  log:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: \$PWD/log
  backups:
    driver: local
    driver_opts:
      type: 'none'
      o: 'bind'
      device: \$PWD/backups

networks:
  net-erisp:
    external: true
EOF

# Step 5: Create flectra.conf file
cat > config/flectra.conf <<EOF
[options]
addons_path = /mnt/extra-addons
admin_passwd = $admin_password
csv_internal_sep = ,
data_dir = /var/lib/flectra
db_host = db
db_maxconn = 64
db_name = False
db_password = flectra
db_port = 5432
db_sslmode = prefer
db_template = template0
db_user = flectra
dbfilter = 
demo = {}
email_from = False
geoip_database = /usr/share/GeoIP/GeoLite2-City.mmdb
http_enable = True
http_interface = 
http_port = 7073
import_partial = 
limit_memory_hard = 4294967296
limit_memory_soft = 3758096384
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
limit_time_real_cron = -1
list_db = True
log_db = False
log_db_level = warning
log_handler = :INFO
log_level = info
logfile = 
longpolling_port = 7072
max_cron_threads = 2
osv_memory_age_limit = False
osv_memory_count_limit = False
pg_path = 
pidfile = 
proxy_mode = False
reportgz = False
screencasts = 
screenshots = /tmp/flectra_tests
server_wide_modules = base,web
smtp_password = False
smtp_port = 25
smtp_server = localhost
smtp_ssl = False
smtp_user = False
syslog = False
test_enable = False
test_file = 
test_tags = None
transient_age_limit = 1.0
translate_modules = ['all']
unaccent = False
upgrade_path = 
without_demo = False
workers = 0
EOF

# Step 6: Run docker-compose up
docker-compose up -d

# Step 7: Add Nginx reverse proxy configuration
#xyz=$instance_name
##cat > /home/kptevta/services/nginx/sites-enabled/$instance_name-nginx-reverse-proxy <<EOF
##upstream $instance_name-business4x-com {
##    server $instance_name:7073 weight=1 fail_timeout=1080s;
##}
##upstream $instance_name-business4x-com-im {
##    server $instance_name:7072 weight=1 fail_timeout=1080s;
##}
##server {
##    listen 80;
##    server_name $instance_name.business4x.com;
    #rewrite ^(.*) https://$host$1 permanent;
##    server_tokens off;

##    location /.well-known/acme-challenge/ {
##        root /var/www/certbot;
##    }

##    location / {
##        return 301 https://\$host\$request_uri;
##    }
##    client_max_body_size 1000m;
##}
##server {
##    listen 443;
##    server_name $instance_name.business4x.com;
##    proxy_read_timeout 1090s;
##    proxy_connect_timeout 1090s;
##    proxy_send_timeout 1090s;

##    client_max_body_size 1000m;
##    server_tokens off;

##    ssl_certificate /etc/letsencrypt/live/$instance_name.business4x.com/fullchain.pem;
##    ssl_certificate_key /etc/letsencrypt/live/$instance_name.business4x.com/privkey.pem;
##    include /etc/letsencrypt/options-ssl-nginx.conf;
##    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

#    # ssl settings
##    ssl on;
#    keepalive_timeout 60;
#    ssl_session_timeout 30m;
#
    # limit ciphers
    # ssl_ciphers 'ECDHE-RSA-AES138-GCM-SHA256:ECDHE-ECDSA-AES138-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES138-GCM-SHA256:DHE-DSS-AES138-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES138-SHA256:ECDHE-ECDSA-AES138-SHA256:ECDHE-RSA-AES138-SHA:ECDHE-ECDSA-AES138-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES138-SHA256:DHE-RSA-AES138-SHA:DHE-DSS-AES138-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES138-GCM-SHA256:AES256-GCM-SHA384:AES138-SHA256:AES256-SHA256:AES138-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
    # ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    # ssl_prefer_server_ciphers    on;

    # proxy header and settings
    # Add Headers for odoo proxy mode
##    proxy_set_header Host \$host;
##    proxy_set_header X-Real-IP \$remote_addr;
##    proxy_set_header X-Forwarded-Host \$host;
##    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
##    proxy_redirect off;

    # Let the OpenERP web service know that we're using HTTPS, otherwise
    # it will generate URL using http:// and not https://
##    proxy_set_header X-Forwarded-Proto https;
    #proxy_set_header X-Forwarded-Proto $scheme;

    # odoo log files
##    access_log /var/log/nginx/access-$instance_name-business4x-com.log;
##    error_log  /var/log/nginx/error-$instance_name-business4x-com.log;

    # increase proxy buffer size
##    proxy_buffers 16 64k;
##    proxy_buffer_size 138k;

    # force timeouts if the backend dies
##    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

    # enable data compression
##    gzip on;
    # gzip_min_length 1100;
    # gzip_buffers 4 32k;
    # gzip_types text/plain application/x-javascript text/xml text/css;

##    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    # gzip_vary on;

    # cache some static data in memory for 60mins.
    # under heavy load this should relieve stress on the OpenERP web interface a bit.
##    location ~* /web/static/ {
##        proxy_cache_valid 200 60m;
##        proxy_buffering    on;
##        expires 864000;
##        proxy_pass http://$instance_name-business4x-com;
##    }

##    location / {
##        proxy_redirect off;
##        proxy_pass http://$instance_name-business4x-com;
##    }
    
##    location /longpolling {
##        proxy_connect_timeout       1800;
##        proxy_send_timeout          1800;
##        proxy_read_timeout          1800;
##        send_timeout                1800;
##        proxy_pass http://$instance_name-business4x-com-im;
##    }

##}




##EOF


##cd /home/kptevta/services/nginx
##sed -i "s/\(domains=(\).*/\1$instance_name.business4x.com)/g"  init-letsencrypt.sh


##chmod +x /home/kptevta/services/nginx/init-letsencrypt.sh
##cd /home/kptevta/services/nginx
##sleep 10
##yes | ./init-letsencrypt.sh


