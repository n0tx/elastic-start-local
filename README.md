# ELK + Filebeat REST API Logger  
  
  
## Kibana Dashboard  
  
<img width="1436" height="848" alt="image" src="https://github.com/user-attachments/assets/42b31f8b-cb1b-4410-bfbf-b7359e6dfa93" />  
  
#  
  
Project ini merupakan contoh setup **Elasticsearch + Logstash + Kibana + Filebeat** untuk mengumpulkan, mem‑parse, menyimpan dan mem‑visualisasikan **REST API logs** (dummy) melalui skrip `restapi-log.sh`.  
  
#  
  
<img width="1437" height="855" alt="image" src="https://github.com/user-attachments/assets/c08537a4-632f-4df2-94b0-bf4079ea5dc0" />  
  
  
## Fitur  
  
- 🚀 **ELK Stack**: Elasticsearch, Logstash, Kibana dan Filebeat dijalankan lewat Docker Compose  
- 📥 **Filebeat**: "tail" file log aplikasi dan kirim ke Logstash  
- 🛠️ **Logstash**: `grok` parsing custom, konversi timestamp, dan routing ke Elasticsearch  
- 📝 **Dummy log generator**: `restapi-log.sh` membuat 30 baris log CRUD REST API dengan format lengkap (IP, user, timestamp, method, endpoint, status, size, latency, referrer, user-agent)  
- 📊 **Kibana**: dashboard dan visualisasi (request rate, status distribution, latency, top endpoints, success vs error)  
  
## Bagaimana project ini dibuat  
  
1. **Install Elasticsearch & Kibana**  
    
   ```bash
   curl -fsSL https://elastic.co/start-local | sh
   ```  
     
2. **Menambahkan Docker Image Logstash & Filebeat**  
  
- Di `docker-compose.yml`, tambahkan dua service:  
  
   ```yaml
   services:
     logstash:
       image: docker.elastic.co/logstash/logstash:${ES_LOCAL_VERSION}
       container_name: ${LOGSTASH_LOCAL_CONTAINER_NAME:-logstash}
       depends_on:
         elasticsearch:
           condition: service_healthy
       volumes:
         - ./config/logstash/pipeline:/usr/share/logstash/pipeline:ro
       ports:
         - "5044:5044"
       environment:
         - LS_JAVA_OPTS=-Xms256m -Xmx256m
       healthcheck:
         test: ["CMD-SHELL","curl --fail localhost:9600 || exit 1"]
         interval: 10s
         timeout: 10s
         retries: 5
   
     filebeat:
       image: docker.elastic.co/beats/filebeat:${ES_LOCAL_VERSION}
       container_name: ${FILEBEAT_LOCAL_CONTAINER_NAME:-filebeat-local}
       user: root
       command:
         - filebeat
         - -e
         - --strict.perms=false
         - -c
         - /usr/share/filebeat/filebeat.yml
       volumes:
         - ./config/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
         - ./logs:/usr/share/filebeat/logs:ro
       depends_on:
         - logstash
   ```  
  
3. **Membuat Konfigurasi Logstash & Filebeat**    
  
- Buat pipeline Logstash di `config/logstash/pipeline/logstash.conf`  
  
  ```bash
   input {
     beats {
      port => 5044
     }
   }
   
   filter {
     grok {
       match => {
         "message" => [
           "%{IP:clientip} - %{WORD:user_id} \[%{TIMESTAMP_ISO8601:timestamp}\] \"%{WORD:method} %{URIPATHPARAM:endpoint} HTTP/%{NUMBER:http_version}\" %{NUMBER:status:int} %{NUMBER:bytes:int} %{NUMBER:latency:int}ms \"%{URI:referrer}\" \"%{GREEDYDATA:agent}\""
         ]
       }
     }
   
     date {
       match   => [ "timestamp", "ISO8601" ]
       target  => "@timestamp"
     }
   
     mutate {
       add_field => { "result" => "%{status}" }
     }
     if [status] >= 400 {
       mutate { replace => { "result" => "error" } }
     } else {
       mutate { replace => { "result" => "success" } }
     }
   }
   
   output {
     elasticsearch {
       hosts => ["http://elasticsearch:9200"]
       user => "elastic"
       password => "${ES_LOCAL_PASSWORD:IVbUSoha}"
       index => "restapi-logs-%{+YYYY.MM.dd}"
     }
     stdout { codec => rubydebug }
   }
  ```
  
- Konfigurasi Filebeat di `config/filebeat/filebeat.yml` untuk “tail” `logs/*.log` dan kirim ke Logstash  

  ```yaml
   filebeat.inputs:
   - type: filestream
     enabled: true
     paths:
       - /usr/share/filebeat/logs/*.log
   
   output.logstash:
     hosts: ["logstash:5044"]
   
   setup.kibana:
     host: "kibana:5601"
     username: "elastic"
     password: "${ES_LOCAL_PASSWORD}"
  
4. **Membuat dummy REST API log**  
  
   Skrip `restapi-log.sh` menghasilkan baris‑baris log di `logs/access.log`  
  
   ```bash
   #!/usr/bin/env bash
   cd "$(dirname "$0")"
   
   declare -a methods=(GET POST PUT DELETE)
   declare -a endpoints=("/api/items" "/api/items/1" "/api/items/2" "/api/users" "/api/users/42")
   declare -a users=("guest" "user123" "admin" "alice" "bob")
   declare -a statuses=(200 201 204 400 401 403 404 500)
   declare -a referrers=("-" "https://app.example.com/dashboard" "https://app.example.com/login")
   declare -a user_agents=(
     "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.5790.170 Safari/537.36"
     "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15"
     "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Firefox/102.0"
   )
   
   base_ts="2025-07-15T04:00:00+07:00"
   
   for i in {1..30}; do
     m=${methods[$((RANDOM % ${#methods[@]}))]}
     e=${endpoints[$((RANDOM % ${#endpoints[@]}))]}
     u=${users[$((RANDOM % ${#users[@]}))]}
     s=${statuses[$((RANDOM % ${#statuses[@]}))]}
     size=$((RANDOM % 500 + 20))
     latency=$((RANDOM % 200 + 10))
     ref=${referrers[$((RANDOM % ${#referrers[@]}))]}
     ua=${user_agents[$((RANDOM % ${#user_agents[@]}))]}
     ip="192.168.$((RANDOM % 255)).$((RANDOM % 255))"
   
     echo "${ip} - ${u} [${base_ts}] \"${m} ${e} HTTP/1.1\" ${s} ${size} ${latency}ms \"${ref}\" \"${ua}\"" \
       >> logs/access.log
   done
   
   echo "30 baris CRUD log REST API ditambahkan ke logs/access.log"
   ```
  
## Referensi  
  
[Local development installation (quickstart)](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/local-development-installation-quickstart)  
  
[Logstash Input Beats](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-beats.html)  
  
[Logstash Filter Grok](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html)  
  
[Logstash Output Elasticsearch](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-elasticsearch.html)  
  
[ChatGPT](https://chatgpt.com)  
  
## Requirement
- Docker  
- Docker Compose  
  
  
## Cara Menjalankan Project  

### Menjalankan ELK + Filebeat  
  
1. **Clone repository**

```bash
git clone https://github.com/n0tx/elastic-star-local.git
```
  
2. **Masuk direktori project**

```bash
cd elastic-star-local
```
  
3. **Start semua service**

```bash
./start.sh
```
  
4. **Tunggu semua service up**

```bash
docker ps --format "{{.Names}}: {{.Image}} -> {{.Status}}"
```  
  
5. **Generate dummy REST API logs**

```bash
sudo su
./restapi-log.sh
```
  
### Monitoring ELK + Filebeat  
  
1. **Periksa daftar index di Elasticsearch**
  
Dari daftar index, index akan ditandai dengan `yellow open   restapi-logs-*`,   
sesuai nama index pada konfigurasi `logstash.conf`  
  
```bash
curl -u elastic:${ES_LOCAL_PASSWORD} 'http://localhost:9200/_cat/indices?v'
```    
  
2. **Query lewat curl**  
  
```bash
curl -u elastic:${ES_LOCAL_PASSWORD} 'http://localhost:9200/restapi-logs-*/_search?pretty'
```    
  
3. **Akses Kibana**  
  
Buka [http://localhost:5601](http://localhost:5601) → Discover / Dashboard untuk melihat data di index `restapi-logs-*`  
  
## Struktur Direktori  
  
```text
┌──[~/elastic-start-local]
└─$ tree                                     
.
├── config
│   ├── filebeat
│   │   └── filebeat.yml
│   ├── logstash
│   │   └── pipeline
│   │       └── logstash.conf
│   └── telemetry.yml
├── docker-compose.yml
├── logs
│   └── access.log
├── restapi-logs.sh
├── start.sh
├── stop.sh
└── uninstall.sh

6 directories, 9 files
```
  
## Perintah Penting saat Development ELK + Filebeat  
    
Rangkuman perintah penting yang membantu proses development, troubleshooting, dan verifikasi pipeline ELK + Filebeat.  
    
### 1. Cek Status Container / Service
> Memastikan container sudah berjalan dan melihat status
```bash
docker ps --format "{{.Names}}: {{.Image}} -> {{.Status}}"  # Daftar container dengan nama, image, dan status
docker ps                                                   # Daftar container sedang berjalan
```
  
### 2. Melihat Log Service
> Menampilkan output `stdout/stderr` dari container secara real-time  
```bash
docker-compose logs -f elasticsearch   # Log Elasticsearch
docker-compose logs -f kibana          # Log Kibana
docker-compose logs -f logstash        # Log Logstash
docker-compose logs -f filebeat        # Log Filebeat
```
  
### 3. (Re)Build & Start Ulang Semua Service
> Setelah melakukan perubahan pada file konfigurasi (Logstash, Filebeat, docker-compose, dsb.), jalankan perintah berikut untuk membangun ulang image, men‑recreate semua container, dan memastikan setiap service memuat konfigurasi terbaru secara menyeluruh
```bash
docker-compose up -d --build --force-recreate
```
  
### 4. Restart Service Tertentu
> Jalankan ulang container tanpa mempengaruhi yang lain
```bash
docker-compose restart logstash        # Restart Logstash setelah ubah konfigurasi
```
   
### 5. Masuk ke Shell Container
> Untuk inspeksi langsung file, konfigurasi, atau menjalankan perintah di dalam container
```bash
docker exec -it filebeat-local bash   # Masuk ke shell container filebeat
```
    
### 6. Verifikasi Konfigurasi & Konektivitas Filebeat
> Test apakah filebeat.yml valid dan koneksi ke Logstash berfungsi
```bash
docker exec filebeat-local filebeat test config    # Cek validitas filebeat.yml
docker exec filebeat-local filebeat test output    # Cek koneksi ke Logstash (5044)
```

  
