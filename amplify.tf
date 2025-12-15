resource "aws_amplify_app" "frontend" {
  name       = "cv-cloud-resume-frontend"
  repository = var.github_repository
  
  # OAuth token for third-party source control system (GitHub) checks
  access_token = var.github_token

  # The default build spec
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        build:
          commands: []
      artifacts:
        baseDirectory: frontend
        files:
          - '**/*'
      cache:
        paths: []
  EOT
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "main"

  # Enable auto build
  enable_auto_build = true
}

resource "aws_amplify_domain_association" "domain" {
  app_id      = aws_amplify_app.frontend.id
  domain_name = "chalichen.cat"

  # Subdomain 'cv.chalichen.cat' -> branch 'main'
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "cv"
  }

  # wait_for_verification = false # Sometimes helps prevents timeouts in terraform
}

# Create DNS record in Cloudflare for the subdomain
resource "cloudflare_record" "cv_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "cv"
  value   = "${aws_amplify_branch.main.branch_name}.${aws_amplify_app.frontend.default_domain}"
  type    = "CNAME"
  proxied = true # Or false depending on SSL preference, true usually fine
}
