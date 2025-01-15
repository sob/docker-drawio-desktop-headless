#!/usr/bin/env bats

. tests/base.bats

@test "Export a drawio file as pdf" {
  docker_test "" 0 "export-file1" "tests/data" -x file1.drawio
}

@test "Export a drawio file as pdf with electron security warning" {
  docker_test "-e ELECTRON_DISABLE_SECURITY_WARNINGS=false" 0 "output-electron-security-warning" "tests/data" -x file1.drawio
}

@test "Export a drawio file with space in its name" {
  docker_test "" 0 "export-file2" "tests/data" -x "file 2.drawio"
}

@test "Export as non-root" {
  local current_uid=$(id -u)
  local current_gid=$(id -g)

  # Create directories in the test data folder
  mkdir -p tests/data/home/.config/electron
  mkdir -p tests/data/home/.config/draw.io-desktop
  mkdir -p tests/data/home/.cache

  # Set permissions
  chmod -R 777 tests/data/home

  docker_test "--user ${current_uid}:${current_gid} --env HOME=/data/home --env ELECTRON_USER_DATA_DIR=/data/home/.config/electron" 0 "export-non-root" "tests/data" -x file4.drawio
}

@test "Export using unknown argument" {
  docker_test "" 0 "export-file1" "tests/data" --export file1.drawio --wrong-argument
}

@test "Export with check command" {
  docker_test "" 1 "export-check-firstrun" "tests/data" -export --check file3.drawio
  docker_test "" 1 "export-check-secondrun" "tests/data" -export --check file3.drawio
  docker_test "" 1 "export-check-thirdrun" "tests/data" -export file3.drawio
}
