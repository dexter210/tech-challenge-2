# Create the EKS control plane.
resource "aws_eks_cluster" "main" {
  name     = "tech-challenge-2-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = [var.allowed_api_cidr]
  }

  # Make sure the cluster role has its permissions first.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster
  ]

  tags = {
    Name = "tech-challenge-2-cluster"
  }
}

# Create the managed group of EC2 worker nodes.
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "tech-challenge-2-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.public[*].id

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 4
  }

  # Make sure the node role has its permissions first.
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.ecr_read_only,
    aws_iam_role_policy_attachment.vpc_cni,
    aws_route_table_association.public
  ]

  tags = {
    Name = "tech-challenge-2-nodes"
  }
}