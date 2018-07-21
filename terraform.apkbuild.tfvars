instance_type = "t2.medium"
build_command = [
    "chmod +x /tmp/build.sh",
    "/tmp/build.sh docker_build /tmp/apkbuild ''"
]
