resource "aws_ecs_cluster" "main" {
  name = "tf-ecs-cluster"
}


resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions = templatefile("./task_definitions/app.json", {
    name : "app",
    cpu : var.fargate_cpu,
    memory : var.fargate_memory,
    image : var.app_image,
    port : var.app_port
  })
}

resource "aws_ecs_service" "main" {
  name            = "tf_ecs_service"
  task_definition = aws_ecs_task_definition.app.arn
  cluster         = aws_ecs_cluster.main.id
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private[0].id, aws_subnet.private[1].id, aws_subnet.private[2].id]
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    container_name   = "app"
    container_port   = var.app_port
    target_group_arn = aws_alb_target_group.app.id
  }

  depends_on = [aws_alb.main]
}
