instance_type = "c5.large"
build_command = [
    "chmod +x /tmp/build.sh",
    "/tmp/build.sh docker_build /tmp/apkbuild ''"
]
