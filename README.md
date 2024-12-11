# s3-backend/backend.tf
--- s3 backend ve DynamoDB kaynakları yalnızca bir kez oluşturulmalı ve yapılandırılmalıdır.
--- GitHub Actions dosyasına bu yapılandırmayı tekrar eklemenize gerek yok.
--- Her job çalıştırıldığında terraform init işlemi yapılabilir, ancak backend oluşturma işlemi her işte yapılmamalıdır.

# AWS-ECS-FARGATE