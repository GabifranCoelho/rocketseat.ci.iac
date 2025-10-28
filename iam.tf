resource "aws_iam_openid_connect_provider" "oidc-git" {
  url = "https://token.actions.githubusercontent.com"

  # precisa ser exatamente este host:
  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "7560d6f40fa55195f740ee2b1b7c0b4836cbe103"
  ]

  tags = {
    IAC = "True"
  }
}

resource "aws_iam_role" "tf_role" {
  name = "tf-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc-git.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # audience esperado pelo provider da AWS
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # restrinja ao SEU repositório/branch
            "token.actions.githubusercontent.com:sub" = [
              "repo:GabifranCoelho/rocketseat.ci.iac:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })

  tags = {
    IAC = "True"
  }
}


resource "aws_iam_role" "app-runner-role" {
  name = "app-runner-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Service : "build.apprunner.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role" "ecr_role" {
  name = "ecr_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc-git.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # audience esperado pelo provider da AWS
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # restrinja ao SEU repositório/branch
            "token.actions.githubusercontent.com:sub" = [
              "repo:GabifranCoelho/rocketseat.ci.api:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })

  # Inline policy equivalente ao seu aws_iam_role_policy "ecr_push"
  inline_policy {
    name = "ecr-app-permission"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid      = "Statement1",
          Action   = "apprunner:*",
          Effect   = "Allow",
          Resource = "*"
        },
        {
          Sid = "Statement2",
          Action = [
            "iam:PassRole",
            "iam:CreateServiceLinkedRole"
          ],
          Effect   = "Allow",
          Resource = "*"
        },
        {
          Sid    = "ECRPushPull",
          Effect = "Allow",
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:PutImage",
            "ecr:BatchGetImage",
            "ecr:DescribeImages",
            "ecr:DescribeRepositories",
            "ecr:GetDownloadUrlForLayer"

            # opcional — só deixe se quer que a pipeline crie repo quando não existir
            # "ecr:CreateRepository"
          ],
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    IAC = "True"
  }
}



# resource "aws_iam_openid_connect_provider" "oidc-git" {
#   url = "https://token.actions.githubusercontent.com"
#   client_id_list = [
#     "sts.amazonws.com"
#   ]

#   thumbprint_list = [
#     "7560d6f40fa55195f740ee2b1b7c0b4836cbe103"
#   ]  

#   tags = {
#     IAC = "True"
#   }
# }

# resource "aws_iam_role" "ecr_role" {
#   name = "ecr_role"

#   assume_role_policy = jsonencode({
#     Version   = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.oidc-git.arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringEquals = {
#             "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
#           }
#           StringLike = {
#             # Restrinja ao seu repositório e branch:
#             "token.actions.githubusercontent.com:sub" = [
#               "repo:GabifranCoelho/rocketseat.ci.api:ref:refs/heads/main"
#             ]
#           }
#         }
#       }
#     ]
#   })

#   tags = {
#     IAC = "True"
#   }
# }

# # Permissões mínimas para push no ECR (inline)
# resource "aws_iam_role_policy" "ecr_push" {
#   role = aws_iam_role.ecr_role.id
#   policy = jsonencode({
#     Version   = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:CompleteLayerUpload",
#           "ecr:InitiateLayerUpload",
#           "ecr:UploadLayerPart",
#           "ecr:PutImage",
#           "ecr:BatchGetImage",
#           "ecr:DescribeImages",
#           "ecr:DescribeRepositories",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:CreateRepository"        # opcional, remova se preferir gerenciar via IaC
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }