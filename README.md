# ELK REST API Logger

<img width="1436" height="848" alt="image" src="https://github.com/user-attachments/assets/42b31f8b-cb1b-4410-bfbf-b7359e6dfa93" />

#

Project ini memberikan setup lengkap **Elasticsearch + Logstash + Kibana + Filebeat** untuk mengumpulkan, mem‑parse, dan mem‑visualisasikan **REST API logs** (dummy) melalui skrip `restapi-log.sh`.

## Fitur

- 🚀 **ELK Stack**: Elasticsearch, Logstash, Kibana dijalankan lewat Docker Compose  
- 📥 **Filebeat**: “tail” file log aplikasi dan kirim ke Logstash  
- 🛠️ **Logstash**: `grok` parsing custom, konversi timestamp, dan routing ke Elasticsearch  
- 📝 **Dummy log generator**: `restapi-log.sh` membuat 30 baris log CRUD REST API dengan format lengkap (IP, user, timestamp, method, endpoint, status, size, latency, referrer, user-agent)  
- 📊 **Kibana**: dashboard dan visualisasi (request rate, status distribution, latency, top endpoints, success vs error)

## Cara project ini dibuat

1. **Install Elasticsearch & Kibana**  
   ```bash
   curl -fsSL https://elastic.co/start-local | sh
   ```

2. **Tambahkan Logstash & Filebeat**

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

- Buat pipeline Logstash di `config/logstash/pipeline/logstash.conf`

  ```conf
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
  

