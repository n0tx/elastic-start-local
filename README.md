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


