resource "aws_ecr_repository" "app" {
  name                 = "tech-challenge-2-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "tech-challenge-2-app"
  }
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the application image"
  value       = aws_ecr_repository.app.repository_url
}