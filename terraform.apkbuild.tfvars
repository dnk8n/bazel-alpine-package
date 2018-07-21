instance_type = "c5.18xlarge"
build_command = [
    "chmod +x /tmp/build.sh",
    "/tmp/build.sh docker_build /tmp/apkbuild ''"
]
