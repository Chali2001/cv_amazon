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

# Create DNS record in Cloudflare for the subdomain (The website itself)
resource "cloudflare_record" "cv_cname" {
  zone_id = var.cloudflare_zone_id
  name    = "cv"
  value   = "${aws_amplify_branch.main.branch_name}.${aws_amplify_app.frontend.default_domain}"
  type    = "CNAME"
  proxied = true
}

# --- SSL Validation Automation ---
# Parse the validation record provided by Amplify
locals {
  # The string is like "_x1x2x3.domain.com. CNAME _y1y2y3.acm-validations.aws."
  # We split by " CNAME "
  verification_parts = split(" CNAME ", aws_amplify_domain_association.domain.certificate_verification_dns_record)
  
  # The name part is the first element, usually with a trailing dot we might need to remove not strictly needed for cloudflare provider which handles it
  verification_name  = trim(local.verification_parts[0], ".")
  verification_value = trim(local.verification_parts[1], ".")
}

# Create the validation CNAME in Cloudflare automatically
resource "cloudflare_record" "verification_cname" {
  zone_id = var.cloudflare_zone_id
  name    = local.verification_name
  value   = local.verification_value
  type    = "CNAME"
  proxied = false # MUST be false (DNS Only) for Amazon to verify it
}
