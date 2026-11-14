workspace "my_module" {
  model {
    u = person "User"
    s = softwareSystem "System" {
      w = container "Web"
    }
    u -> w "Uses"
  }
  views {
    systemContext s "SystemContext" {
      include *
      autolayout lr
    }
    container s "Containers" {
      include *
      autolayout lr
    }
  }
}
