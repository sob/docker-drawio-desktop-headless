#!/usr/bin/env bats

setup() {
    if command -v podman &> /dev/null; then
        CONTAINER_RUNTIME="podman"
    elif command -v docker &> /dev/null; then
        CONTAINER_RUNTIME="docker"
    else
        echo "Neither Podman nor Docker is installed"
        exit 1
    fi
}

docker_test() {
  # Get parameters
  local docker_opts="$1 --tmpfs /tmp:rw,size=100M --shm-size=1g"
  local status=$2
  local output_file=$3
  local data_folder=$4
  shift
  shift
  shift
  shift

  # Run command
  echo $CONTAINER_RUNTIME container run -t $docker_opts -w /data -v $(pwd)/${data_folder:-}:/data ${DOCKER_IMAGE} "$@" >>tests/output/$output_file-command.log
  run $CONTAINER_RUNTIME container run -t $docker_opts -w /data -v $(pwd)/${data_folder:-}:/data ${DOCKER_IMAGE} "$@"

  # Remove timed logging tags on electron logs by default.
  echo "$output" | tee "tests/output/$output_file.log" | sed 's#\[.*:.*/.*\..*:.*:.*\(.*\)\] ##' >"tests/output/$output_file-comp.log"

  # Test output
  if [ -f "tests/expected/$output_file.log" ]; then
    diff -u --strip-trailing-cr "tests/expected/$output_file.log" "tests/output/$output_file-comp.log" >"tests/output/$output_file-diff.log"
  elif [ -f "tests/expected/uniq-$output_file.log" ]; then
    diff -u --strip-trailing-cr "tests/expected/uniq-$output_file.log" <(sort -u "tests/output/$output_file-comp.log") >"tests/output/$output_file-diff.log"
  fi
  if [ -f "tests/output/$output_file-diff.log" ]; then
    [ "$(cat "tests/output/$output_file-diff.log")" = "" ]
  fi
}
